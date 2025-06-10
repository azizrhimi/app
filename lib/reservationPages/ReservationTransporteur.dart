import 'dart:io';
import 'package:amira_app/reservationPages/ReservationActionPage.dart';
import 'package:amira_app/notificationsPages/notificationsTransporteur.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../shared/colors.dart';

class ReservationTransporteur extends StatefulWidget {
  const ReservationTransporteur({super.key});

  @override
  State<ReservationTransporteur> createState() => _ReservationTransporteurState();
}

class _ReservationTransporteurState extends State<ReservationTransporteur> {
  final _user = FirebaseAuth.instance.currentUser;
  DateTime selectedDate = DateTime.now();

  /// Fonction pour marquer un trajet comme terminé, calculer le prix total et notifier le client
  Future<void> _markAsCompleted({
    required BuildContext context,
    required String reservationId,
    required Map<String, dynamic> reservationData,
  }) async {
    final durationController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Marquer le trajet comme terminé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Véhicule : ${reservationData['car_nom'] ?? 'Inconnu'}'),
            Text('Client : ${reservationData['client_nom'] ?? ''} ${reservationData['client_prenom'] ?? ''}'.trim()),
            const SizedBox(height: 16),
            TextFormField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Durée du trajet (heures)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                prefixIcon: const Icon(Icons.access_time),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer', style: TextStyle(color: mainColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final durationHours = double.tryParse(durationController.text.trim());
    if (durationHours == null || durationHours <= 0) {
      Get.snackbar('Erreur', 'Veuillez entrer une durée valide.', snackPosition: SnackPosition.TOP);
      return;
    }

    try {
      if (reservationData['car_id'] == null) {
        Get.snackbar('Erreur', 'Identifiant de la voiture manquant.', snackPosition: SnackPosition.TOP);
        return;
      }

      // Récupérer les données de la voiture avec une gestion d'erreur améliorée
      final carSnapshot = await FirebaseFirestore.instance
          .collection('voitures')
          .doc(reservationData['car_id'])
          .get();

      if (!carSnapshot.exists) {
        Get.snackbar('Erreur', 'Voiture non trouvée dans Firestore.', snackPosition: SnackPosition.TOP);
        return;
      }

      final carData = carSnapshot.data()!;
      final pricePerDayStr = carData['prix_jour']?.toString() ?? '';
      final pricePerDay = double.tryParse(pricePerDayStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

      if (pricePerDay <= 0) {
        Get.snackbar('Erreur', 'Prix par jour invalide ou manquant dans Firestore. Veuillez vérifier les données de la voiture.', snackPosition: SnackPosition.TOP);
        return;
      }

      final pricePerHour = pricePerDay / 24;
      final totalPrice = pricePerHour * durationHours;

      if (reservationData['client_id'] == null) {
        Get.snackbar('Erreur', 'Identifiant du client manquant.', snackPosition: SnackPosition.TOP);
        return;
      }

      await FirebaseFirestore.instance
          .collection('reservation')
          .doc(reservationId)
          .update({
        'status': 'terminée',
        'duration_hours': durationHours,
        'total_price': totalPrice,
        'completed_at': Timestamp.now(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'client_id': reservationData['client_id'],
        'transporteur_id': _user!.uid,
        'titre': 'Trajet terminé',
        'contenu': 'Votre trajet avec ${reservationData['car_nom'] ?? 'un véhicule'} est terminé. '
            'Montant total : ${totalPrice.toStringAsFixed(2)} € pour $durationHours heure(s).',
        'reservation_id': reservationId,
        'date': Timestamp.now(),
      });

      Get.snackbar('Succès', 'Trajet marqué comme terminé et client notifié.', snackPosition: SnackPosition.TOP);
    } catch (e) {
      debugPrint('Erreur: $e');
      Get.snackbar('Erreur', 'Impossible de marquer le trajet comme terminé: $e', snackPosition: SnackPosition.TOP);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Mes Réservations",
            style: TextStyle(fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: SvgPicture.asset("assets/images/notifications.svg",
                height: 36, width: 36),
            onPressed: () {
              Get.to(() => const NotificationTrasporteur(),
                  transition: Transition.downToUp);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 🗓️ Filtre par jour
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final day = DateFormat.E('fr_FR').format(date);
                final dayNum = DateFormat.d().format(date);
                final isSelected = date.day == selectedDate.day &&
                    date.month == selectedDate.month &&
                    date.year == selectedDate.year;

                return GestureDetector(
                  onTap: () => setState(() => selectedDate = date),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? mainColor : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(day,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black)),
                        Text(dayNum,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // 📋 Liste ou état vide
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reservation')
                  .where('chauffeur_id', isEqualTo: _user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = data['datetime']?.toDate();
                  return date != null &&
                      date.year == selectedDate.year &&
                      date.month == selectedDate.month &&
                      date.day == selectedDate.day;
                }).toList();

                if (filtered.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/images/no_work.svg",
                        height: 200,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Aucune réservation pour ce jour.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // Statut
                    final rawStatus = data['status'] as String?;
                    final status = rawStatus ?? 'en_attente';
                    String statusLabel;
                    Color statusColor;
                    switch (status) {
                      case 'acceptée':
                        statusLabel = 'Acceptée';
                        statusColor = Colors.green;
                        break;
                      case 'refusée':
                        statusLabel = 'Refusée';
                        statusColor = Colors.red;
                        break;
                      case 'terminée':
                        statusLabel = 'Terminée';
                        statusColor = Colors.blue;
                        break;
                      default:
                        statusLabel = 'En attente';
                        statusColor = Colors.orange;
                    }

                    // Date/heure
                    final date = data['datetime']?.toDate();
                    final formattedDate = date != null
                        ? DateFormat("dd/MM/yyyy – HH:mm", "fr_FR")
                            .format(date)
                        : 'N/A';

                    // Photo de la voiture
                    final carImage = (data['car_image'] as String?) 
                        ?? 'assets/images/placeholder_car.png';

                    final carNom = data['car_nom'] as String? ?? '';
                    final carPrixJour =
                        data['car_prix_jour'] as String? ?? '';

                    // Détails réservation
                    final depart = data['depart'] as String? ?? '';
                    final destination = data['destination'] as String? ?? '';
                    final typeVehicule =
                        data['type_vehicule'] as String? ?? '';
                    final typeBagage = data['type_bagage'] as String? ?? '';
                    final prixPropose = data['prix'] as String? ?? '';
                    final durationHours = data['duration_hours'] as double?;
                    final totalPrice = data['total_price'] as double?;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReservationActionPage(
                              reservationData: data,
                              reservationId: doc.id,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
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
                            // 🚗 Photo du véhicule
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                              ),
                              child: carImage.startsWith('http')
                                  ? Image.network(
                                      carImage,
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    )
                                  : carImage.startsWith('assets/')
                                      ? Image.asset(
                                          carImage,
                                          width: double.infinity,
                                          height: 140,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(carImage),
                                          width: double.infinity,
                                          height: 140,
                                          fit: BoxFit.cover,
                                        ),
                            ),

                            // 🏷️ Chip statut
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Chip(
                                  label: Text(
                                    statusLabel,
                                    style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor:
                                      statusColor.withOpacity(0.1),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                ),
                              ),
                            ),

                            // 📝 Infos texte
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(carNom,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text("$carPrixJour €/jour",
                                      style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Text(
                                      "${data['client_nom']} ${data['client_prenom']}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    const Icon(Icons.location_on_outlined,
                                        color: Colors.black54, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(depart,
                                          style:
                                              const TextStyle(fontSize: 14)),
                                    ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.flag_outlined,
                                        color: Colors.black54, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(destination,
                                          style:
                                              const TextStyle(fontSize: 14)),
                                    ),
                                  ]),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    const Icon(Icons.directions_car,
                                        color: Colors.black54, size: 16),
                                    const SizedBox(width: 6),
                                    Text(typeVehicule,
                                        style: const TextStyle(fontSize: 14)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.luggage,
                                        color: Colors.black54, size: 16),
                                    const SizedBox(width: 6),
                                    Text(typeBagage,
                                        style: const TextStyle(fontSize: 14)),
                                  ]),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    const Text("💶",
                                        style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text("$prixPropose €",
                                        style: const TextStyle(fontSize: 14)),
                                  ]),
                                  if (status == 'terminée' && durationHours != null && totalPrice != null) ...[
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      const Text("⏳",
                                          style: TextStyle(fontSize: 16)),
                                      const SizedBox(width: 6),
                                      Text("${durationHours.toStringAsFixed(1)} h",
                                          style: const TextStyle(fontSize: 14)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Text("💰",
                                          style: TextStyle(fontSize: 16)),
                                      const SizedBox(width: 6),
                                      Text("${totalPrice.toStringAsFixed(2)} €",
                                          style: const TextStyle(fontSize: 14)),
                                    ]),
                                  ],
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(formattedDate,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black45,
                                        )),
                                  ),
                                  if (status == 'acceptée') ...[
                                    const SizedBox(height: 12),
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () => _markAsCompleted(
                                          context: context,
                                          reservationId: doc.id,
                                          reservationData: data,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: mainColor,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(25)),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                        ),
                                        child: const Text(
                                          'Marquer comme terminé',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}