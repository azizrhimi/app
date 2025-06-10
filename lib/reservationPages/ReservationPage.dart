import 'package:amira_app/Screens/screens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../shared/colors.dart';

class ReservationPage extends StatefulWidget {
  final Map<String, dynamic> transporteur;
  final Map<String, dynamic> carData;
  final String carId;

  const ReservationPage({
    super.key,
    required this.transporteur,
    required this.carData,
    required this.carId,
  });

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final _departCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _vehiculeCtrl = TextEditingController();
  final _bagageCtrl = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitReservation() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _selectedDate == null ||
        _selectedTime == null) {
      Get.snackbar(
        'Erreur',
        'Veuillez remplir tous les champs',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.transparent,
        colorText: Colors.black,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté.");

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      final userData = userDoc.data()!;
      final nom = userData['nom'] ?? '';
      final prenom = userData['prenom'] ?? '';

      final datetime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final pickupList = await locationFromAddress(_departCtrl.text);
      final dropoffList = await locationFromAddress(_destinationCtrl.text);

      final pickup = GeoPoint(
        pickupList.first.latitude,
        pickupList.first.longitude,
      );
      final dropoff = GeoPoint(
        dropoffList.first.latitude,
        dropoffList.first.longitude,
      );

      // ⚠️ IMPORTANT : on lit désormais 'images_urls'
      final images = (widget.carData['images_urls'] as List<dynamic>?)?.cast<String>() ?? [];
      final firstImage = images.isNotEmpty
          ? images.first
          : 'assets/images/placeholder_car.png';

      await FirebaseFirestore.instance
          .collection("reservation")
          .add({
        "client_id": user.uid,
        "client_nom": nom,
        "client_prenom": prenom,
        "chauffeur_id": widget.transporteur['uid'],
        "car_id": widget.carId,
        "car_nom": widget.carData['nom'] ?? '',
        "car_prix_jour": widget.carData['prix_jour'] ?? '',
        "car_image": firstImage,
        "depart": _departCtrl.text,
        "destination": _destinationCtrl.text,
        "pickup": pickup,
        "dropoff": dropoff,
        "type_vehicule": _vehiculeCtrl.text,
        "type_bagage": _bagageCtrl.text,
        "date": DateFormat('yyyy-MM-dd').format(_selectedDate!),
        "heure": _selectedTime!.format(context),
        "created_at": Timestamp.now(),
        "datetime": datetime,
        'is_Paied': 'non',
        "status": "en_attente",
      });

      await FirebaseFirestore.instance
          .collection("notificationsTransporteur")
          .add({
        "client_id": user.uid,
        "transporteur_id": widget.transporteur['uid'],
        "titre": "Nouvelle Réservation",
        "contenu": "$nom $prenom a réservé votre voiture.",
        "date": Timestamp.now(),
      });

      Get.snackbar(
        'Succès',
        'Réservation enregistrée !',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.transparent,
        colorText: Colors.black,
      );
      Get.off(() => const Screens());
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.transparent,
        colorText: Colors.black,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 On récupère la liste 'images_urls'
    final images = (widget.carData['images_urls'] as List<dynamic>?)?.cast<String>() ?? [];
    final firstImage = images.isNotEmpty
        ? images.first
        : 'assets/images/placeholder_car.png';
    final carName = widget.carData['nom'] as String? ?? '';
    final carPrice = widget.carData['prix_jour'] as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Réservation",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Aperçu véhicule
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Image(
                      image: firstImage.startsWith('http')
                          ? NetworkImage(firstImage)
                          : AssetImage(firstImage) as ImageProvider,
                      width: 100,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(carName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("$carPrice €/jour",
                            style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sélection date
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _selectedDate == null
                    ? "Sélectionner une date"
                    : DateFormat('dd/MM/yyyy').format(_selectedDate!),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),

            // Sélection heure
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                _selectedTime == null
                    ? "Sélectionner une heure"
                    : _selectedTime!.format(context),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() => _selectedTime = picked);
                }
              },
            ),

            const SizedBox(height: 20),

            _buildTextField(_departCtrl, "Adresse de départ", Icons.location_on),
            _buildTextField(_destinationCtrl, "Adresse de destination", Icons.flag),
            _buildTextField(_vehiculeCtrl, "Type de véhicule", Icons.fire_truck),
            _buildTextField(_bagageCtrl, "Type de bagage", Icons.luggage),

            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                const Text("Transporteur : ", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.transporteur['chauffeur_nom'] ?? "N/A"),
              ],
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Confirmer la réservation",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25)),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Champ requis" : null,
      ),
    );
  }
}