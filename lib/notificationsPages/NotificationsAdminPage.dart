// NotificationsAdminPage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsAdminPage extends StatelessWidget {
  const NotificationsAdminPage({super.key});

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
          'Notifications Admin',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notificationsAdmin')
            .snapshots(), // Requête simplifiée : pas de where ni orderBy
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('Chargement des notifications admin...');
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Erreur Firestore: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Une erreur est survenue lors du chargement des notifications.'),
                  const SizedBox(height: 8),
                  Text('Détails: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Réessayer ou naviguer ailleurs
                      Navigator.pop(context);
                    },
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          // Filtrer et trier côté client
          final filteredDocs = docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['admin_id'] == user.uid;
              })
              .toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aDate = (aData['date'] as Timestamp?)?.toDate() ?? DateTime(0);
              final bDate = (bData['date'] as Timestamp?)?.toDate() ?? DateTime(0);
              return bDate.compareTo(aDate); // Tri descendant
            });

          if (filteredDocs.isEmpty) {
            debugPrint('Aucune notification admin trouvée.');
            return const Center(child: Text('Aucune notification disponible.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final titre = data['titre'] ?? 'N/A';
              final contenu = data['contenu'] ?? 'N/A';
              final date = (data['date'] as Timestamp?)?.toDate();
              final formattedDate = date != null
                  ? DateFormat('dd/MM/yyyy – HH:mm', 'fr_FR').format(date)
                  : 'N/A';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(contenu),
                      const SizedBox(height: 4),
                      Text(formattedDate, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  onTap: () {
                    debugPrint('Notification sélectionnée: $titre');
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