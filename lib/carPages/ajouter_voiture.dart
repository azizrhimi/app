import 'dart:typed_data';
import 'package:amira_app/Screens/screens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../shared/colors.dart';

class AjouterVoitureModern extends StatefulWidget {
  const AjouterVoitureModern({super.key});
  @override
  State<AjouterVoitureModern> createState() => _AjouterVoitureModernState();
}

class _AjouterVoitureModernState extends State<AjouterVoitureModern> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _dayCtrl = TextEditingController();
  final _hourCtrl = TextEditingController();
  final _hpCtrl = TextEditingController();
  final _seatCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<Uint8List?> _images = List.filled(4, null);
  final List<XFile?> _pickedFiles = List.filled(4, null);

  bool _isSaving = false;

  Future<void> _pickImage(int i) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _images[i] = bytes;
        _pickedFiles[i] = file;
      });
    }
  }

  Future<String> _uploadImage(XFile file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putData(await file.readAsBytes());
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_pickedFiles.every((f) => f == null)) {
      Get.snackbar("Erreur", "Veuillez ajouter au moins une photo.",
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          snackPosition: SnackPosition.TOP);
      return;
    }

    setState(() => _isSaving = true);

    List<String> imageUrls = [];
    for (int i = 0; i < _pickedFiles.length; i++) {
      if (_pickedFiles[i] != null) {
        final url = await _uploadImage(
          _pickedFiles[i]!,
          "voitures/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg",
        );
        imageUrls.add(url);
      }
    }

    await FirebaseFirestore.instance.collection('voitures').add({
      'id_transporteur': user.uid,
      'nom': _nomCtrl.text.trim(),
      'type': _typeCtrl.text.trim(),
      'prix_jour': _dayCtrl.text.trim(),
      'prix_heure': _hourCtrl.text.trim(),
      'hp': _hpCtrl.text.trim(),
      'seats': _seatCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'images_urls': imageUrls,
      'chauffeur_nom': user.displayName ?? 'chauffeur_nom',
      'created_at': Timestamp.now(),
    });

    setState(() => _isSaving = false);

    Get.snackbar(
      "Succès",
      "Voiture ajoutée",
      backgroundColor: Colors.transparent,
      colorText: Colors.black,
      snackPosition: SnackPosition.TOP,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      isDismissible: true,
    );

    Get.off(() => const Screens());
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      prefixIcon: Icon(icon, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: mainColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _decoration(hint, icon),
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: Get.back,
        ),
        centerTitle: true,
        title: const Text(
          "Nouvelle Voiture",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nomCtrl, "Nom de la voiture", Icons.directions_car,
                  validator: (v) => v!.isEmpty ? "Requis" : null),
              const SizedBox(height: 12),
              _buildTextField(_typeCtrl, "Type (Auto / Manuelle)", Icons.settings,
                  validator: (v) => v!.isEmpty ? "Requis" : null),
              const SizedBox(height: 12),
              _buildTextField(_dayCtrl, "Prix par jour", Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Requis" : null),
              const SizedBox(height: 12),
              _buildTextField(_hourCtrl, "Prix par heure", Icons.access_time,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Requis" : null),
              const SizedBox(height: 12),
              _buildTextField(_hpCtrl, "Chevaux (hp)", Icons.speed,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Requis" : null),
              const SizedBox(height: 12),
              _buildTextField(_seatCtrl, "Nombre de sièges", Icons.event_seat,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Requis" : null),
              const SizedBox(height: 12),
              _buildTextField(_descCtrl, "Description", Icons.info, maxLines: 3),
              const SizedBox(height: 20),
              const Text("Photos (max 4)",
                  style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(4, (i) {
                  final b = _images[i];
                  return GestureDetector(
                    onTap: () => _pickImage(i),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        image: b != null
                            ? DecorationImage(
                                image: MemoryImage(b), fit: BoxFit.cover)
                            : null,
                      ),
                      child: b == null
                          ? const Icon(Icons.add_photo_alternate, color: Colors.grey)
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.white, size: 24)
                    : const Text(
                        "Ajouter la Voiture",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
