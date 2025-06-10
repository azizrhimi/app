import 'package:amira_app/carPages/edit_car.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import '../../shared/colors.dart';
import '../reservationPages/ReservationPage.dart';

class CarDetailsPage extends StatefulWidget {
  final Map<String, dynamic> carData;
  final String carId;

  const CarDetailsPage({
    super.key,
    required this.carData,
    required this.carId,
  });

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  int _selectedImageIndex = 0;
  final _me = FirebaseAuth.instance.currentUser;

  void _goToReservation() {
    final ownerId = widget.carData['id_transporteur'] ?? '';
    final ownerName = widget.carData['chauffeur_nom'] ?? '';
    final ownerPhone = widget.carData['chauffeur_telephone'] ?? '';
    final ownerEmail = widget.carData['email'] ?? '';

    final Map<String, dynamic> transporteurMap = {
      'uid': ownerId,
      'chauffeur_nom': ownerName,
      'chauffeur_telephone': ownerPhone,
      'email': ownerEmail,
    };

    Get.to(
      () => ReservationPage(
        transporteur: transporteurMap,
        carData: widget.carData,
        carId: widget.carId,
      ),
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images =
        (widget.carData['images_urls'] as List<dynamic>?)?.cast<String>() ??
            [];
    final carImages =
        images.isNotEmpty ? images : ['assets/images/placeholder_car.png'];

    final name = widget.carData['nom'] ?? '';
    final priceDay = widget.carData['prix_jour'] ?? '';
    final power = widget.carData['hp'] ?? '';
    final gear = widget.carData['type'] ?? '';
    final seats = widget.carData['seats'] ?? '';
    final priceHour = widget.carData['prix_heure'] ?? '';
    final description = widget.carData['description'] ?? '';
    final ownerId = widget.carData['id_transporteur'] ?? '';
    final isOwner = _me != null && _me.uid == ownerId;
    // Récupère l'URL ou le chemin
final imageUrl = carImages[_selectedImageIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Détails de la voiture",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Iconsax.edit_2, color: Colors.black),
              onPressed: () {
                Get.to(
                  () => ModifierVoitureModern(
                    docId: widget.carId,
                    initialData: widget.carData,
                  ),
                  transition: Transition.rightToLeft,
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Image principale
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
             child: ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: imageUrl.startsWith('http')
      ? Image.network(
          imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        )
      : Image.asset(
          imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
),
            ),
          ),
          const SizedBox(height: 12),
          // Miniatures
          SizedBox(
            height: 70,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: carImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final img = carImages[i];
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: img.startsWith('assets/')
                        ? Image.asset(
                            img,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            img,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Titre & prix
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text("$priceDay TND/jour",
                    style:
                        const TextStyle(fontSize: 16, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Fiche technique
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _infoCard(Icons.speed, "Engine", "$power hp"),
                _infoCard(Icons.local_gas_station, "Fuel Type", "Petrol"),
                _infoCard(Icons.settings, "Transmission", gear),
                _infoCard(Icons.event_seat, "Seats", "$seats sièges"),
                _infoCard(Icons.access_time, "Prix/h", "$priceHour TND/h"),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(description,
                  style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ),
          ),
          const Spacer(),
          // Bouton Réserver
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _goToReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Réserver",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _infoCard(IconData icon, String title, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.black87),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
