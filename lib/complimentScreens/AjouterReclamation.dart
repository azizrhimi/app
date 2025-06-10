import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:amira_app/registerScreens/registartiontextfield.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../shared/colors.dart';

class AjouterReclamation extends StatefulWidget {
  const AjouterReclamation({super.key});

  @override
  State<AjouterReclamation> createState() => _AjouterReclamationState();
}

class _AjouterReclamationState extends State<AjouterReclamation> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final titreController = TextEditingController();
  final descriptionController = TextEditingController();

  bool isLoading = false;

  Future<void> submitComplaint() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print('Utilisateur non connecté lors de la soumission de la réclamation.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vous devez être connecté.")),
        );
        setState(() => isLoading = false);
        return;
      }

      print('Ajout de la réclamation pour l\'utilisateur: ${user.uid}');
      final reclamationRef = await FirebaseFirestore.instance.collection("reclamations").add({
        "titre": titreController.text.trim(),
        "description": descriptionController.text.trim(),
        "user_id": user.uid,
        "created_at": Timestamp.now(),
        "status": "pending",
      });

      print('Réclamation ajoutée avec ID: ${reclamationRef.id}');

      print('Recherche des admins dans la collection users...');
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        print('Admins trouvés: ${adminSnapshot.docs.length}');
        for (var adminDoc in adminSnapshot.docs) {
          final adminId = adminDoc.id;
          print('Envoi d\'une notification à l\'admin ID: $adminId');
          await FirebaseFirestore.instance.collection('notificationsAdmin').add({
            'admin_id': adminId,
            'titre': 'Nouvelle réclamation',
            'contenu': 'Un client a soumis une réclamation : "${titreController.text}".',
            'date': Timestamp.now(),
          });
          print('Notification ajoutée pour l\'admin ID: $adminId');
        }
      } else {
        print('Aucun admin trouvé dans la collection users. Vérifiez le champ "role" dans la collection "users".');
      }

      setState(() => isLoading = false);

      Get.snackbar(
        "Succès",
        "Votre réclamation a bien été envoyée.",
        backgroundColor: Colors.transparent,
        colorText: Colors.black,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );

      titreController.clear();
      descriptionController.clear();

      Get.back();
    } catch (e) {
      setState(() => isLoading = false);
      print('Erreur lors de l\'envoi de la réclamation: $e');
      Get.snackbar(
        "Erreur",
        "Une erreur s'est produite lors de l'envoi de votre réclamation: $e",
        backgroundColor: Colors.transparent,
        colorText: Colors.black,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Soumettre Réclamation",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/images/reclamation.svg', height: 150),
              const SizedBox(height: 30),
              RegistrationTextField(
                icon: Icons.title,
                text: "Titre de la réclamation",
                controller: titreController,
                validator: (value) => value!.isEmpty ? "Ce champ est requis" : null,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: descriptionController,
                validator: (value) =>
                    value!.isEmpty ? "Veuillez entrer une description" : null,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Décrivez votre réclamation ici...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Soumettre",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    titreController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}