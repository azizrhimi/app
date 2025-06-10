import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:amira_app/Screens/screens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:quickalert/quickalert.dart';
import '../../shared/colors.dart';
import 'registartiontextfield.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  GlobalKey<FormState> formstate = GlobalKey<FormState>();
  bool isPasswordVisible = true;
  TextEditingController nomController = TextEditingController();
  TextEditingController prenomController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;

  File? _pickedImage;

  Future<void> pickImageFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Erreur lors de l\'upload : $e');
      return null;
    }
  }

  Future<void> register() async {
    setState(() {
      isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      String? imageUrl = '';
      if (_pickedImage != null) {
        imageUrl = await uploadImage(_pickedImage!);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
        "nom": nomController.text,
        "prenom": prenomController.text,
        "email": emailController.text,
        "password": passwordController.text,
        "role": "client",
        "anniversaire": '',
        "phone": '',
        "url_image": imageUrl ?? '',
        "uid": FirebaseAuth.instance.currentUser!.uid,
      });

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Screens()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Erreur...',
          text: 'Mot de passe faible !',
        );
      } else if (e.code == 'email-already-in-use') {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Erreur...',
          text: 'Utilisateur existe déjà !',
        );
      }
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Oops...',
        text: 'Vérifiez vos informations !',
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
        child: Form(
          key: formstate,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text("Inscription", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Rejoignez notre communauté en quelques étapes simples.", style: TextStyle(color: Colors.black)),
                const SizedBox(height: 30),
                Center(
                  child: GestureDetector(
                    onTap: pickImageFromGallery,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) : null,
                      child: _pickedImage == null
                          ? const Icon(Icons.camera_alt, color: mainColor, size: 30)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: RegistrationTextField(
                        icon: CupertinoIcons.person,
                        text: "Nom",
                        controller: nomController,
                        validator: (value) => value!.isEmpty ? "Entrez un nom valide" : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RegistrationTextField(
                        icon: CupertinoIcons.person,
                        text: "Prénom",
                        controller: prenomController,
                        validator: (value) => value!.isEmpty ? "Entrez un prénom valide" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                RegistrationTextField(
                  icon: CupertinoIcons.mail,
                  text: "Email",
                  controller: emailController,
                  validator: (email) {
                    return email!.contains(RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$"))
                        ? null
                        : "Entrez un email valide";
                  },
                ),
                const SizedBox(height: 30),
                TextFormField(
                  validator: (value) => value!.isEmpty ? "Entrez un mot de passe" : null,
                  obscureText: isPasswordVisible,
                  controller: passwordController,
                  decoration: inputDecoration("Mot de passe"),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  validator: (value) => value != passwordController.text ? "Les mots de passe ne correspondent pas" : null,
                  obscureText: isPasswordVisible,
                  controller: confirmPasswordController,
                  decoration: inputDecoration("Confirmer mot de passe"),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text("Mot de passe oublié ?", style: TextStyle(color: Colors.black)),
                ),
                const SizedBox(height: 35),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formstate.currentState!.validate()) {
                            await register();
                          } else {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.error,
                              title: 'Erreur',
                              text: 'Veuillez remplir tous les champs',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          padding: const EdgeInsets.all(13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: isLoading
                            ? LoadingAnimationWidget.staggeredDotsWave(
                                color: whiteColor,
                                size: 32,
                              )
                            : const Text(
                                "Enregistrer",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: whiteColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const Gap(20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      suffixIcon: GestureDetector(
        onTap: () {
          setState(() {
            isPasswordVisible = !isPasswordVisible;
          });
        },
        child: Icon(
          isPasswordVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
          color: Colors.black,
          size: 22,
        ),
      ),
      prefixIcon: const Icon(CupertinoIcons.lock_rotation_open, color: Colors.black, size: 22),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black, fontSize: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Colors.black),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Colors.black),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );
  }
}
