import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amira_app/shared/colors.dart';

class AdminFeedbacksPage extends StatelessWidget {
  const AdminFeedbacksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedbacks'),
        backgroundColor: mainColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('feedbacks').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final feedbacks = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Transporteur ID")),
                DataColumn(label: Text("Note")),
                DataColumn(label: Text("Commentaire")),
                DataColumn(label: Text("Action")),
              ],
              rows: feedbacks.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DataRow(cells: [
                  DataCell(Text(data['transporteur_id'] ?? 'Inconnu')),
                  DataCell(Text('${data['note'] ?? '0'}')),
                  DataCell(Text(data['commentaire'] ?? 'Sans commentaire')),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Supprimer le feedback'),
                          content: const Text('Voulez-vous supprimer ce feedback ?'),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('feedbacks')
                              .doc(doc.id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Feedback supprimé avec succès')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur lors de la suppression : $e')),
                          );
                        }
                      }
                    },
                  )),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}