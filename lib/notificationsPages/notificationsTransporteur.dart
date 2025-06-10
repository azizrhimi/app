import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../shared/colors.dart';

class NotificationTrasporteur extends StatefulWidget {
  const NotificationTrasporteur({super.key});

  @override
  State<NotificationTrasporteur> createState() => _NotificationTrasporteurState();
}

class _NotificationTrasporteurState extends State<NotificationTrasporteur> {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notificationsTransporteur')
              .where('transporteur_id', isEqualTo: userId)
              // .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text("Erreur lors du chargement"));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: mainColor,
                  size: 40,
                ),
              );
            }

            final notifications = snapshot.data!.docs;

            if (notifications.isEmpty) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                 
                  const SizedBox(height: 20),
                  Center(
                    child: const Text(
                      "Aucune notification pour l’instant.",
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final notif = notifications[index].data() as Map<String, dynamic>;
                final titre = notif['titre'] ?? "Notification";
                final contenu = notif['contenu'] ?? "Contenu indisponible";
                final date = (notif['date'] as Timestamp).toDate();

                final formattedDate = DateFormat('dd MMM yyyy – HH:mm', 'fr_FR').format(date);

                final isPositive = titre.toString().toLowerCase().contains("acceptée");

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre de la notification
                      Row(
                        children: [
                          SvgPicture.asset(
                            isPositive
                                ? "assets/images/point.svg"
                                : "assets/images/point.svg",
                            width: 20,
                            // color: isPositive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              titre,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Contenu
                      Text(
                        contenu,
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                      ),

                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(formattedDate, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
