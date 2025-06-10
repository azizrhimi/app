import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'reservations_client_details.dart';

class AcceptedReservationsPage extends StatelessWidget {
  const AcceptedReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Veuillez vous connecter pour voir vos réservations.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mes réservations acceptées',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservation')
            .where('client_id', isEqualTo: user.uid)
            .where('status', whereIn: ['acceptée', 'terminée']) // ✅ affichage des deux
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("Aucune réservation acceptée ou terminée."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final docSnap = docs[i];
              final reservationId = docSnap.id;
              final data = docSnap.data()! as Map<String, dynamic>;

              final dateTime = (data['datetime'] as Timestamp).toDate();
              final formattedDate = DateFormat("dd/MM/yyyy – HH:mm", "fr_FR").format(dateTime);

              final carImage = data['car_image'] as String? ?? 'assets/images/placeholder_car.png';
              final carName = data['car_nom'] as String? ?? '';
              final carPrice = data['car_prix_jour'] as String? ?? '';

              final depart = data['depart'] as String? ?? '';
              final destination = data['destination'] as String? ?? '';
              final vehicule = data['type_vehicule'] as String? ?? '';
              final bagage = data['type_bagage'] as String? ?? '';
              final prixProp = data['prix'] as String? ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AcceptedReservationDetailPage(
                        reservation: data,
                        reservationId: reservationId,
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
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: Image(
                          image: carImage.startsWith('http')
                              ? NetworkImage(carImage)
                              : AssetImage(carImage) as ImageProvider,
                          width: double.infinity,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              carName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$carPrice €/jour",
                              style: const TextStyle(color: Colors.black54, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(depart, style: const TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.flag_outlined, size: 16, color: Colors.black54),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(destination, style: const TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.directions_car, size: 16, color: Colors.black54),
                                const SizedBox(width: 6),
                                Text(vehicule, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.luggage, size: 16, color: Colors.black54),
                                const SizedBox(width: 6),
                                Text(bagage, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text("💶", style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text("$prixProp €", style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 13, color: Colors.black45),
                              ),
                            ),
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
    );
  }
}
