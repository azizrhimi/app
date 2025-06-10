import 'package:amira_app/Screens/TransporteurDetailsPage.dart';
import 'package:amira_app/complimentScreens/AjouterReclamation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../shared/colors.dart';

class TransporteurList extends StatefulWidget {
  const TransporteurList({super.key});

  @override
  State<TransporteurList> createState() => _TransporteurListState();
}

class _TransporteurListState extends State<TransporteurList> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Transporteurs",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔍 Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Rechercher par nom...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'transporteur')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Aucun transporteur trouvé."),
                  );
                }

                final transporteurs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nom =
                      (data['chauffeur_nom'] ?? '').toString().toLowerCase();
                  return nom.contains(searchQuery);
                }).toList();

                if (transporteurs.isEmpty) {
                  return const Center(child: Text("Aucun résultat trouvé."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transporteurs.length,
                  itemBuilder: (context, index) {
                    final data =
                        transporteurs[index].data() as Map<String, dynamic>;

                    final imageUrl = data['photo_vehicule_1'] ?? '';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TransporteurDetailsPage(transporteur: data),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.white,
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // 👤 Avatar FirebaseStorage ou SVG
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.grey[100],
                                backgroundImage: (imageUrl != null &&
                                        imageUrl.toString().isNotEmpty)
                                    ? NetworkImage(imageUrl)
                                    : null,
                                child: (imageUrl == null ||
                                        imageUrl.toString().isEmpty)
                                    ? SvgPicture.asset(
                                        'assets/images/avatar_placeholder.svg',
                                        width: 40,
                                        height: 40,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),

                              // Infos transporteur
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['chauffeur_nom'] ?? 'Nom inconnu',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${data['vehicule_type'] ?? 'Type inconnu'} - ${data['chauffeur_experience'] ?? '0'} ans',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '📞 ${data['chauffeur_telephone'] ?? 'Numéro inconnu'}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ➕ Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(
            () => const AjouterReclamation(),
            transition: Transition.downToUp,
          );
        },
        backgroundColor: mainColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
