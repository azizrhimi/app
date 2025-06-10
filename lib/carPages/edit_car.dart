import 'dart:typed_data';
import 'dart:io';
import 'package:amira_app/Screens/screens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../shared/colors.dart';

class ModifierVoitureModern extends StatefulWidget {
  final String docId;
  final Map<String,dynamic> initialData;

  const ModifierVoitureModern({
    super.key,
    required this.docId,
    required this.initialData,
  });

  @override
  State<ModifierVoitureModern> createState() => _ModifierVoitureModernState();
}

class _ModifierVoitureModernState extends State<ModifierVoitureModern> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _dayCtrl;
  late TextEditingController _hourCtrl;
  late TextEditingController _hpCtrl;
  late TextEditingController _seatCtrl;
  late TextEditingController _descCtrl;

  final ImagePicker _picker = ImagePicker();
  late List<Uint8List?> _images;
  late List<String?>   _imagePaths;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // init controllers
    _nomCtrl   = TextEditingController(text: widget.initialData['nom']);
    _typeCtrl  = TextEditingController(text: widget.initialData['type']);
    _dayCtrl   = TextEditingController(text: widget.initialData['prix_jour']);
    _hourCtrl  = TextEditingController(text: widget.initialData['prix_heure']);
    _hpCtrl    = TextEditingController(text: widget.initialData['hp']);
    _seatCtrl  = TextEditingController(text: widget.initialData['seats']);
    _descCtrl  = TextEditingController(text: widget.initialData['description']);

    // load existing paths
    final existing = (widget.initialData['images_paths'] as List<dynamic>?)
            ?.cast<String>() ??
        [];
    _imagePaths = List<String?>.filled(4, null);
    for (var i = 0; i < existing.length && i < 4; i++) {
      _imagePaths[i] = existing[i];
    }
    // no preview bytes initially
    _images = List<Uint8List?>.filled(4, null);
  }

  Future<void> _pickImage(int i) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _images[i]     = bytes;
        _imagePaths[i] = file.path;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final paths = _imagePaths.where((p) => p != null).cast<String>().toList();

    await FirebaseFirestore.instance
        .collection('voitures')
        .doc(widget.docId)
        .update({
      'nom'           : _nomCtrl.text.trim(),
      'type'          : _typeCtrl.text.trim(),
      'prix_jour'     : _dayCtrl.text.trim(),
      'prix_heure'    : _hourCtrl.text.trim(),
      'hp'            : _hpCtrl.text.trim(),
      'seats'         : _seatCtrl.text.trim(),
      'description'   : _descCtrl.text.trim(),
      'images_paths'  : paths,
    });

    setState(() => _isSaving = false);

    Get.snackbar(
      "Succès",
      "Voiture mise à jour",
      backgroundColor: Colors.transparent,
      colorText: Colors.black,
      snackPosition: SnackPosition.TOP,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      isDismissible: true,
    );

    Get.off(()=>Screens()); // retour à la liste
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
    TextEditingController c,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
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
          "Modifier la voiture",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nomCtrl,  "Nom de la voiture", Icons.directions_car,
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
              const Text(
                "Photos (max 4)",
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(4, (i) {
                  final preview = _images[i];
                  final path    = _imagePaths[i];
                  Widget child;
                  if (preview != null) {
                    child = Image.memory(preview, fit: BoxFit.cover);
                  } else if (path != null && path.startsWith('/')) {
                    child = Image.file(File(path), fit: BoxFit.cover);
                  } else {
                    child = const Icon(Icons.add_photo_alternate, color: Colors.grey);
                  }
                  return GestureDetector(
                    onTap: () => _pickImage(i),
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 24)
                    : const Text("Mettre à jour", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
