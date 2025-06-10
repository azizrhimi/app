import 'package:amira_app/carPages/ajouter_voiture.dart';
import 'package:amira_app/carPages/car_details.dart';
import 'package:amira_app/shared/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class CarListPage extends StatelessWidget {
  final String? transporteurId;

  const CarListPage({super.key, this.transporteurId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final ownerUid = transporteurId ?? user?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Voitures",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (user != null && ownerUid == user.uid)
            IconButton(
              icon: const Icon(Iconsax.add_circle, color: Colors.black),
              onPressed: () {
                Get.to(() => const AjouterVoitureModern(),
                    transition: Transition.rightToLeft);
              },
            ),
        ],
      ),
      body: user == null
          ? const Center(child: Text("Utilisateur non connecté"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('voitures')
                  .where('id_transporteur', isEqualTo: ownerUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Aucune voiture ajoutée."));
                }

                final cars = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cars.length,
                  itemBuilder: (context, index) {
                    final doc = cars[index];
                    final data = doc.data()! as Map<String, dynamic>;

                    final title = data['nom'] as String? ?? '—';
                    final priceDay = data['prix_jour'] as String? ?? '—';
                    final power = data['hp'] as String? ?? '—';
                    final gear = data['type'] as String? ?? '—';
                    final seats = data['seats'] as String? ?? '—';
                    final images =
                        (data['images_urls'] as List<dynamic>?)?.cast<String>() ?? [];
                    final image = images.isNotEmpty
                        ? images[0]
                        : null;
                    final carId = doc.id;
                    // ignore: unnecessary_null_comparison
                    final isOwner = user != null && user.uid == ownerUid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: image != null
                                ? Image.network(
                                    image,
                                    height: 170,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'assets/images/placeholder_car.png',
                                    height: 170,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "$priceDay TND / jour",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Iconsax.flash, size: 18),
                                          const SizedBox(width: 6),
                                          Text("$power hp"),
                                          const SizedBox(width: 16),
                                          const Icon(Iconsax.setting_4, size: 18),
                                          const SizedBox(width: 6),
                                          Text(gear),
                                          const SizedBox(width: 16),
                                          const Icon(Iconsax.user, size: 18),
                                          const SizedBox(width: 6),
                                          Text("$seats seats"),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Iconsax.eye,
                                          color: Colors.black54),
                                      onPressed: () {
                                        Get.to(
                                          () => CarDetailsPage(
                                            carData: data,
                                            carId: carId,
                                          ),
                                          transition: Transition.rightToLeft,
                                        );
                                      },
                                    ),
                                    if (isOwner)
                                      IconButton(
                                        icon: const Icon(Iconsax.trash,
                                            color: Colors.redAccent),
                                        onPressed: () async {
                                          final delete = await Get.dialog<bool>(
                                            Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              backgroundColor: Colors.white,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(20),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Iconsax.trash,
                                                        size: 40,
                                                        color: Colors.redAccent),
                                                    const SizedBox(height: 16),
                                                    const Text(
                                                      'Supprimer cette voiture ?',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    const Text(
                                                      'Cette action est irréversible.',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                          color: Colors.black54),
                                                    ),
                                                    const SizedBox(height: 24),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: OutlinedButton(
                                                            onPressed: () =>
                                                                Get.back(result: false),
                                                            style: OutlinedButton.styleFrom(
                                                              side: BorderSide(
                                                                  color: mainColor),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        8),
                                                              ),
                                                            ),
                                                            child: const Text('Annuler',
                                                                style: TextStyle(
                                                                    color: mainColor)),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: ElevatedButton(
                                                            onPressed: () =>
                                                                Get.back(result: true),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.redAccent,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                        8),
                                                              ),
                                                            ),
                                                            child: const Text('Supprimer',
                                                                style: TextStyle(
                                                                    color:
                                                                        Colors.white)),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                            barrierDismissible: false,
                                          );

                                          if (delete == true) {
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('voitures')
                                                  .doc(carId)
                                                  .delete();
                                              Get.snackbar(
                                                'Supprimé',
                                                'Voiture supprimée avec succès',
                                                snackPosition:
                                                    SnackPosition.TOP,
                                                backgroundColor:
                                                    Colors.transparent,
                                                colorText: Colors.black,
                                              );
                                            } catch (e) {
                                              Get.snackbar(
                                                'Erreur',
                                                'Impossible de supprimer',
                                                snackPosition:
                                                    SnackPosition.TOP,
                                                backgroundColor:
                                                    Colors.transparent,
                                                colorText: Colors.black,
                                              );
                                            }
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
