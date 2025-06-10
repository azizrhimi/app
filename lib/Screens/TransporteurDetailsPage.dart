import 'package:amira_app/carPages/car_list.dart';
import 'package:amira_app/chatPages/ChatPage.dart';
import 'package:amira_app/shared/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class TransporteurDetailsPage extends StatelessWidget {
  final Map<String, dynamic> transporteur;

  const TransporteurDetailsPage({
    super.key,
    required this.transporteur,
  });

  Widget _infoItem(IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: mainColor, size: 20),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = transporteur['uid'] as String;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Transporteur Details",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(LineAwesomeIcons.comment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    transporteurId: uid,
                    transporteurName:
                        transporteur['chauffeur_nom'] ?? "Transporteur",
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: (transporteur['url_image'] != null &&
                        transporteur['url_image'].toString().isNotEmpty)
                    ? NetworkImage(transporteur['url_image'])
                    : null,
                child: (transporteur['url_image'] == null ||
                        transporteur['url_image'].toString().isEmpty)
                    ? SvgPicture.asset(
                        'assets/images/avatar_placeholder.svg',
                        width: 70,
                        height: 70,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: Text(
                transporteur['chauffeur_nom'] ?? '',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            // Infos
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoItem(Icons.phone,
                        transporteur['chauffeur_telephone'] ?? 'N/A'),
                    _infoItem(Icons.email, transporteur['email'] ?? 'N/A'),
                    _infoItem(Icons.badge,
                        '${transporteur['chauffeur_experience'] ?? '0'} ans'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            // Photos du véhicule
            Row(
              children: [
                const Text("Photos du véhicule",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(LineAwesomeIcons.car_alt_solid),
                  onPressed: () {
                    Get.to(() => CarListPage(transporteurId: uid),
                        transition: Transition.rightToLeft);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  final key = 'photo_vehicule_${index + 1}';
                  final url = transporteur[key] as String?;

                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                      image: DecorationImage(
                        image: (url != null && url.isNotEmpty)
                            ? NetworkImage(url)
                            : const AssetImage(
                                    'assets/images/placeholder_car.png')
                                as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
            // Feedback
            const Text("Feedback Clients",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rates')
                  .where('transporteur_id', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Text(
                    "Aucun feedback pour le moment.",
                    style: TextStyle(color: Colors.black54),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final data = docs[i].data()! as Map<String, dynamic>;
                      final date =
                          (data['date'] as Timestamp).toDate();
                      final dateStr =
                          DateFormat('dd/MM/yy').format(date);
                      final stars = (data['rate'] as num).toDouble();
                      final comment = data['commentaire'] ?? '';
                      final clientImg = data['client_image'] ?? '';
                      final clientName =
                          "${data['client_nom'] ?? ''} ${data['client_prenom'] ?? ''}";

                      return Container(
                        width: 260,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage:
                                      (clientImg.isNotEmpty)
                                          ? NetworkImage(clientImg)
                                          : null,
                                  child: (clientImg.isEmpty)
                                      ? Text(
                                          clientName.isNotEmpty
                                              ? clientName[0]
                                              : '?',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    clientName,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            RatingBarIndicator(
                              rating: stars,
                              itemBuilder: (_, __) => const Icon(Icons.star,
                                  color: Colors.amber),
                              itemCount: 5,
                              itemSize: 20,
                              unratedColor: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 4),
                            Text(dateStr,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Text(
                                comment,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.fade,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
