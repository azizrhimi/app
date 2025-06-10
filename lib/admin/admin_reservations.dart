// admin_reservations.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminReservationsPage extends StatelessWidget {
  const AdminReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Veuillez vous connecter en tant qu\'admin.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Gestion des Réservations',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reservation').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('Chargement des réservations...');
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Erreur Firestore: ${snapshot.error}');
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            debugPrint('Aucune réservation trouvée.');
            return const Center(child: Text('Aucune réservation disponible.'));
          }

          debugPrint('Nombre de réservations: ${docs.length}');

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final reservationId = docs[index].id;
              final clientName = '${data['client_nom'] ?? ''} ${data['client_prenom'] ?? ''}'.trim();
              final carName = data['car_nom'] ?? 'N/A';
              final status = data['status'] ?? 'en_attente';
              final date = (data['datetime'] as Timestamp?)?.toDate();
              final formattedDate = date != null
                  ? DateFormat('dd/MM/yyyy – HH:mm', 'fr_FR').format(date)
                  : 'N/A';

              Color statusColor;
              switch (status) {
                case 'acceptée':
                  statusColor = Colors.green;
                  break;
                case 'refusée':
                  statusColor = Colors.red;
                  break;
                case 'annulée':
                  statusColor = Colors.grey;
                  break;
                default:
                  statusColor = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    'Réservation #$reservationId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Client: $clientName'),
                      Text('Véhicule: $carName'),
                      Text('Date: $formattedDate'),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(status, style: TextStyle(color: statusColor)),
                        backgroundColor: statusColor.withOpacity(0.1),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Naviguer vers une page de détails (optionnel)
                    debugPrint('Réservation sélectionnée: $reservationId');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}