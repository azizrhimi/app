import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:amira_app/shared/colors.dart';

class AdminCarsPage extends StatelessWidget {
  const AdminCarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voitures'),
        backgroundColor: mainColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('voitures').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cars = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Nom")),
                DataColumn(label: Text("Transporteur ID")),
                DataColumn(label: Text("Prix/Jour")),
                DataColumn(label: Text("Prix/Heure")),
                DataColumn(label: Text("Action")),
              ],
              rows: cars.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DataRow(cells: [
                  DataCell(Text(data['nom'] ?? 'Sans nom')),
                  DataCell(Text(data['id_transporteur'] ?? 'Inconnu')),
                  DataCell(Text('${data['prix_jour'] ?? '0'} TND')),
                  DataCell(Text('${data['prix_heure'] ?? '0'} TND')),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Supprimer la voiture'),
                          content: Text('Voulez-vous supprimer la voiture "${data['nom']}" ?'),
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
                              .collection('voitures')
                              .doc(doc.id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Voiture supprimée avec succès')),
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