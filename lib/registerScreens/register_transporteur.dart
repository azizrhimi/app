import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:quickalert/quickalert.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../shared/colors.dart';
import '../Screens/screens.dart';
import 'registartiontextfield.dart';

class RegisterTransporteur extends StatefulWidget {
  const RegisterTransporteur({super.key});

  @override
  State<RegisterTransporteur> createState() => _RegisterTransporteurState();
}

class _RegisterTransporteurState extends State<RegisterTransporteur> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nomChauffeurController = TextEditingController();
  final phoneController = TextEditingController();
  final experienceController = TextEditingController();
  final hauteurController = TextEditingController();
  final largeurController = TextEditingController();
  final longueurController = TextEditingController();
  final cinController = TextEditingController();
  final immatController = TextEditingController();

  String selectedVehiculeType = 'Camion';
  bool hayon = false;
  bool clim = false;
  bool isPasswordVisible = true;
  bool isLoading = false;

  File? chauffeurImage;
  List<File?> vehiculeImages = [null, null, null, null];

  Future<void> pickImage(Function(File) onImagePicked) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) onImagePicked(File(picked.path));
  }

  Future<String> uploadToStorage(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Erreur',
        text: 'Veuillez remplir tous les champs.',
      );
      return;
    }

    if (chauffeurImage == null || vehiculeImages.any((img) => img == null)) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Erreur',
        text: 'Veuillez ajouter toutes les images.',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      final chauffeurImageUrl = await uploadToStorage(
          chauffeurImage!, 'chauffeurs/${cred.user!.uid}/profile.jpg');

      List<String> vehiculeUrls = [];
      for (int i = 0; i < 4; i++) {
        final url = await uploadToStorage(
            vehiculeImages[i]!, 'chauffeurs/${cred.user!.uid}/vehicule_$i.jpg');
        vehiculeUrls.add(url);
      }

      await FirebaseFirestore.instance.collection("users").doc(cred.user!.uid).set({
        "email": emailController.text,
        "password": passwordController.text,
        "role": "transporteur",
        "vehicule_type": selectedVehiculeType,
        "hauteur": hauteurController.text,
        "largeur": largeurController.text,
        "longueur": longueurController.text,
        "hayon": hayon,
        "climatisation": clim,
        "chauffeur_nom": nomChauffeurController.text,
        "chauffeur_telephone": phoneController.text,
        "chauffeur_experience": experienceController.text,
        "cin": cinController.text,
        "immat": immatController.text,
        "url_image": chauffeurImageUrl,
        "photo_vehicule_1": vehiculeUrls[0],
        "photo_vehicule_2": vehiculeUrls[1],
        "photo_vehicule_3": vehiculeUrls[2],
        "photo_vehicule_4": vehiculeUrls[3],
        "uid": cred.user!.uid,
        "isApproved": false, // 🟨 Nouvel attribut pour validation admin
      });

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Screens()),
        (route) => false,
      );
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Erreur',
        text: 'Une erreur est survenue.',
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),
                GestureDetector(
                  onTap: () => pickImage((f) => setState(() => chauffeurImage = f)),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        chauffeurImage != null ? FileImage(chauffeurImage!) : null,
                    child: chauffeurImage == null
                        ? const Icon(Icons.camera_alt, color: mainColor)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                RegistrationTextField(
                  icon: CupertinoIcons.person,
                  text: "Nom et prénom du chauffeur",
                  controller: nomChauffeurController,
                  validator: (value) => value!.isEmpty ? "Veuillez entrer le nom" : null,
                ),
                const SizedBox(height: 20),
                RegistrationTextField(
                  icon: Icons.phone,
                  text: "Numéro de téléphone",
                  controller: phoneController,
                  validator: (value) => value!.isEmpty ? "Veuillez entrer un téléphone" : null,
                ),
                const SizedBox(height: 20),
                RegistrationTextField(
                  icon: Icons.info_outline,
                  text: "Expérience / Compétences",
                  controller: experienceController,
                  validator: (value) => value!.isEmpty ? "Veuillez décrire votre expérience" : null,
                ),
                const SizedBox(height: 20),
                RegistrationTextField(
                  icon: Icons.badge,
                  text: "Numéro CIN (9 chiffres)",
                  controller: cinController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Champ requis";
                    if (value.length != 9) return "Le CIN doit contenir 9 chiffres";
                    return null;
                  },
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                RegistrationTextField(
                  icon: Icons.car_rental,
                  text: "Immatriculation du véhicule",
                  controller: immatController,
                  validator: (value) => value!.isEmpty ? "Champ requis" : null,
                ),
                const SizedBox(height: 20),
                RegistrationTextField(
                  icon: CupertinoIcons.mail,
                  text: "Email",
                  controller: emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Veuillez entrer une adresse email";
                    }
                    final emailRegex = RegExp(r"^[^@]+@[^@]+\.[^@]+");
                    if (!emailRegex.hasMatch(value)) {
                      return "Format de l'email invalide";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _passwordField("Mot de passe", passwordController),
                const SizedBox(height: 20),
                _passwordField("Confirmer mot de passe", confirmPasswordController, confirm: true),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedVehiculeType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                    labelText: "Type de véhicule",
                  ),
                  items: ['Camion', 'Fourgon', 'Voiture utilitaire']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedVehiculeType = val!),
                ),
                const SizedBox(height: 20),
                RegistrationTextField(
                  icon: Icons.height,
                  text: "Hauteur",
                  controller: hauteurController,
                  validator: (v) => v!.isEmpty ? "Champ requis" : null,
                ),
                const SizedBox(height: 10),
                RegistrationTextField(
                  icon: Icons.width_normal,
                  text: "Largeur",
                  controller: largeurController,
                  validator: (v) => v!.isEmpty ? "Champ requis" : null,
                ),
                const SizedBox(height: 10),
                RegistrationTextField(
                  icon: Icons.straighten,
                  text: "Longueur",
                  controller: longueurController,
                  validator: (v) => v!.isEmpty ? "Champ requis" : null,
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: const Text("Hayon élévateur"),
                  value: hayon,
                  onChanged: (val) => setState(() => hayon = val!),
                ),
                CheckboxListTile(
                  title: const Text("Climatisation"),
                  value: clim,
                  onChanged: (val) => setState(() => clim = val!),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Photos du véhicule (4) :",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => pickImage((f) => setState(() => vehiculeImages[i] = f)),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: vehiculeImages[i] != null
                          ? Image.file(vehiculeImages[i]!, fit: BoxFit.cover)
                          : const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_a_photo, color: mainColor),
                                  SizedBox(height: 5),
                                  Text("Ajouter une photo", style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.all(13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: isLoading
                      ? LoadingAnimationWidget.staggeredDotsWave(color: whiteColor, size: 32)
                      : const Text(
                          "Soumettre le formulaire",
                          style: TextStyle(fontSize: 16, color: whiteColor, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField(String hint, TextEditingController controller, {bool confirm = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPasswordVisible,
      validator: (val) {
        if (val == null || val.isEmpty) return "Champ requis";
        if (confirm && val != passwordController.text) {
          return "Les mots de passe ne correspondent pas";
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => isPasswordVisible = !isPasswordVisible),
          child: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }
}
