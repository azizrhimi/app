import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:amira_app/shared/colors.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool isAdmin = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _verifyAdmin();
  }

  Future<void> _verifyAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAllNamed('/login');
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = doc.data()?['role'];

    if (mounted) {
      setState(() {
        isAdmin = role == 'admin';
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Erreur', 'Aucun utilisateur connecté.',
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.red.shade100);
      return;
    }

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Confirmer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        Get.offAllNamed('/login');
      } catch (e) {
        Get.snackbar('Erreur', 'Déconnexion échouée : $e',
            snackPosition: SnackPosition.TOP, backgroundColor: Colors.red.shade100);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isAdmin) {
      return const Scaffold(
        body: Center(child: Text('⛔️ Accès refusé. Vous n’êtes pas administrateur.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tableau de bord Administrateur"),
        backgroundColor: mainColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                print('Redirection vers /notificationsAdmin avec ID: ${user.uid}');
                Get.toNamed('/notificationsAdmin', arguments: user.uid);
              } else {
                Get.snackbar("Erreur", "Utilisateur non connecté !");
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(context, "Utilisateurs", Icons.people, '/adminUsers'),
            _buildCard(context, "Réservations", Icons.event, '/adminReservations'),
            _buildCard(context, "Voitures", Icons.directions_car, '/adminCars'),
            _buildCard(context, "Feedbacks", Icons.feedback, '/adminFeedbacks'),
            _buildCard(context, "Réclamations", Icons.report, '/adminReclamations'),
            _buildCard(context, "Déconnexion", Icons.exit_to_app, null, onTap: _logout),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, String? route, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? (route != null ? () => Get.toNamed(route) : null),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: mainColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
