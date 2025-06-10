import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class TransporteurFeedBackPage extends StatefulWidget {
  final String uid;
  const TransporteurFeedBackPage({super.key, required this.uid});

  @override
  State<TransporteurFeedBackPage> createState() => _TransporteurFeedBackPageState();
}

class _TransporteurFeedBackPageState extends State<TransporteurFeedBackPage> {
  double averageRating = 0.0;

  double _calculateAverage(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return 0.0;
    final total = docs
        .map((e) => (e['rate'] as num).toDouble())
        .reduce((a, b) => a + b);
    return total / docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Feedbacks clients",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rates')
            .where('transporteur_id', isEqualTo: widget.uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Aucun feedback pour le moment.",
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          final average = _calculateAverage(docs);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ⭐️ Moyenne affichée en haut
                Row(
                  children: [
                    const Text(
                      "Note moyenne :",
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    RatingBarIndicator(
                      rating: average,
                      itemBuilder: (_, __) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 22,
                      unratedColor: Colors.grey.shade300,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      average.toStringAsFixed(1),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Liste des feedbacks
                Expanded(
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final data = docs[i].data()! as Map<String, dynamic>;
                      final date = (data['date'] as Timestamp).toDate();
                      final dateStr = DateFormat('dd/MM/yy').format(date);
                      final stars = (data['rate'] as num).toDouble();
                      final comment = data['commentaire'] as String? ?? '';
                      final image = data['client_image'] as String? ?? '';
                      final name = "${data['client_nom'] ?? ''} ${data['client_prenom'] ?? ''}".trim();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
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
                            // Avatar + nom
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: image.isNotEmpty
                                      ? NetworkImage(image)
                                      : null,
                                  child: image.isEmpty
                                      ? Text(
                                          name.isNotEmpty ? name[0] : '?',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name.isNotEmpty ? name : "Client inconnu",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            RatingBarIndicator(
                              rating: stars,
                              itemBuilder: (_, __) =>
                                  const Icon(Icons.star, color: Colors.amber),
                              itemCount: 5,
                              itemSize: 20,
                              unratedColor: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 4),
                            Text(dateStr,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 12),
                            Text(
                              comment,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
