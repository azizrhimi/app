import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:amira_app/chatPages/ChatPage.dart';

class ClientsMessageriePage extends StatefulWidget {
  const ClientsMessageriePage({super.key});

  @override
  State<ClientsMessageriePage> createState() => _ClientsMessageriePageState();
}

class _ClientsMessageriePageState extends State<ClientsMessageriePage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  List<String> uniqueClientIds = [];
  Map<String, Map<String, dynamic>> clientInfos = {};

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  Future<void> fetchClients() async {
    if (currentUser == null) return;

    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('receiver_id', isEqualTo: currentUser!.uid)
        .get();

    final Set<String> clients = {};

    for (var doc in messagesSnapshot.docs) {
      final data = doc.data();
      final senderId = data['sender_id'];
      if (senderId != null) clients.add(senderId);
    }

    for (String id in clients) {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(id).get();
      if (userDoc.exists) {
        clientInfos[id] = userDoc.data()!;
      }
    }

    setState(() {
      uniqueClientIds = clientInfos.keys.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Messages Clients",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: uniqueClientIds.isEmpty
          ? const Center(child: Text("Aucun message reçu."))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: uniqueClientIds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final userId = uniqueClientIds[index];
                final userData = clientInfos[userId];

                return InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          transporteurId: userId,
                          transporteurName:
                              "${userData?['nom']} ${userData?['prenom']}",
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F2FA),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: (userData?['url_image'] != null &&
                                  userData!['url_image'].toString().isNotEmpty)
                              ? NetworkImage(userData['url_image'])
                              : null,
                          child: (userData?['url_image'] == null ||
                                  userData!['url_image'].toString().isEmpty)
                              ? SvgPicture.asset(
                                  'assets/images/avatar_placeholder.svg',
                                  width: 32,
                                  height: 32,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            "${userData?['nom'] ?? ''} ${userData?['prenom'] ?? ''}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.grey, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
