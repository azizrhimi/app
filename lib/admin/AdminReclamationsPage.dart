// admin_reclamations.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminReclamationsPage extends StatelessWidget {
  const AdminReclamationsPage({super.key});

  Future<void> _handleReclamation({
    required BuildContext context,
    required String reclamationId,
    required String clientId,
    required String clientName,
    required bool isResolved,
    required String description,
  }) async {
    final responseCtrl = TextEditingController();
    final status = isResolved ? 'résolue' : 'non_résolue';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Marquer comme $status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Réclamation: $description'),
            const SizedBox(height: 16),
            TextField(
              controller: responseCtrl,
              decoration: const InputDecoration(
                labelText: 'Réponse de l\'admin (facultatif)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Mettre à jour la réclamation
      await FirebaseFirestore.instance
          .collection('reclamations')
          .doc(reclamationId)
          .update({
        'status': status,
        'resolved_at': Timestamp.now(),
        'admin_response': responseCtrl.text.isEmpty ? null : responseCtrl.text,
      });

      // Envoyer une notification au client
      await FirebaseFirestore.instance.collection('notifications').add({
        'client_id': clientId,
        'admin_id': FirebaseAuth.instance.currentUser!.uid,
        'titre': 'Mise à jour de votre réclamation',
        'contenu': 'Votre réclamation a été marquée comme $status. ${responseCtrl.text.isEmpty ? '' : 'Réponse: ${responseCtrl.text}'}',
        'reclamation_id': reclamationId,
        'date': Timestamp.now(),
      });

      Get.snackbar('Succès', 'Réclamation mise à jour et client notifié.');
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la réclamation: $e');
      Get.snackbar('Erreur', 'Impossible de mettre à jour la réclamation.');
    }
  }

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
          'Gestion des Réclamations',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reclamations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('Chargement des réclamations...');
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Erreur Firestore: ${snapshot.error}');
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            debugPrint('Aucune réclamation trouvée.');
            return const Center(child: Text('Aucune réclamation disponible.'));
          }

          debugPrint('Nombre de réclamations: ${docs.length}');

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final reclamationId = docs[index].id;
              final clientName = '${data['client_nom'] ?? ''} ${data['client_prenom'] ?? ''}'.trim();
              final description = data['description'] ?? 'N/A';
              final status = data['status'] ?? 'en_attente';
              final date = (data['created_at'] as Timestamp).toDate();
              final formattedDate = DateFormat('dd/MM/yyyy – HH:mm', 'fr_FR').format(date);

              Color statusColor;
              switch (status) {
                case 'résolue':
                  statusColor = Colors.green;
                  break;
                case 'non_résolue':
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Réclamation #$reclamationId',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text('Client: $clientName'),
                      Text('Description: $description'),
                      Text('Date: $formattedDate'),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(status, style: TextStyle(color: statusColor)),
                        backgroundColor: statusColor.withOpacity(0.1),
                      ),
                      if (status == 'en_attente') ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => _handleReclamation(
                                context: context,
                                reclamationId: reclamationId,
                                clientId: data['client_id'],
                                clientName: clientName,
                                isResolved: true,
                                description: description,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Marquer comme résolue'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _handleReclamation(
                                context: context,
                                reclamationId: reclamationId,
                                clientId: data['client_id'],
                                clientName: clientName,
                                isResolved: false,
                                description: description,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Marquer comme non résolue'),
                            ),
                          ],
                        ),
                      ],
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