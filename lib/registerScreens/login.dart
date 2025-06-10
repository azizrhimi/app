// ✅ login.dart – Complet avec redirection admin/client selon le rôle Firestore
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:quickalert/quickalert.dart';
import 'package:get/get.dart'; // Ajout de GetX pour la navigation
import '../../shared/colors.dart';
import 'package:amira_app/registerScreens/registartiontextfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formstate = GlobalKey<FormState>();
  bool isPasswordVisible = true;
  bool isLoading = false;

  Future<void> login() async {
    print('Tentative de connexion...');
    setState(() {
      isLoading = true;
    });
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) {
        print('Utilisateur null après connexion.');
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Utilisateur non trouvé après connexion.',
        );
      }
      print('Utilisateur connecté : ${user.uid}');

      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        String role = 'client';
        if (user.email == 'admin@email.com') {
          role = 'admin';
        } else if (user.email?.contains('transporteur') ?? false) {
          role = 'transporteur';
        }
        print('Création d\'un nouveau document utilisateur avec rôle : $role');
        await userDoc.set({
          'email': user.email,
          'name': '',
          'role': role,
        });
      }

      final updatedSnapshot = await userDoc.get();
      final role = updatedSnapshot.data()?['role'] ?? 'client';
      print('Rôle de l\'utilisateur : $role');

      if (!mounted) {
        print('Widget non monté, arrêt de la redirection.');
        return;
      }

      if (role == 'admin') {
        print('Redirection vers /adminDashboard...');
        Get.offAllNamed('/adminDashboard');
      } else {
        print('Redirection vers /home...');
        Get.offAllNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      print('Erreur FirebaseAuth : ${e.code} - ${e.message}');
      String message = 'Erreur de connexion';
      if (e.code == 'user-not-found') {
        message = 'Utilisateur non trouvé !';
      } else if (e.code == 'wrong-password') {
        message = 'Mot de passe incorrect !';
      }
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Oops...',
        text: message,
      );
    } catch (e) {
      print('Erreur inattendue lors de la connexion : $e');
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Erreur',
        text: 'Une erreur inattendue s\'est produite : $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Construction de LoginPage...');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'TranspoGo',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
        child: Form(
          key: formstate,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: SvgPicture.asset(
                    'assets/images/car.svg',
                    height: 120.0,
                    width: 120.0,
                    allowDrawingOutsideViewBox: true,
                  ),
                ),
                const SizedBox(height: 30),
                const Row(
                  children: [
                    Text("Connecter", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Accédez à votre espace personnel en toute sécurité.",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                RegistrationTextField(
                  icon: CupertinoIcons.mail,
                  text: "  Email",
                  controller: emailController,
                  validator: (email) {
                    return email != null &&
                            email.contains(RegExp(
                                r"^[a-zA-Z0-9.a-zA-Z0-9.!#\$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"))
                        ? null
                        : "Entrer un email valide";
                  },
                ),
                const SizedBox(height: 30),
                TextFormField(
                  validator: (value) => value == null || value.isEmpty ? "Vérifier le mot de passe" : null,
                  obscureText: isPasswordVisible,
                  controller: passwordController,
                  decoration: InputDecoration(
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() => isPasswordVisible = !isPasswordVisible);
                      },
                      child: Icon(
                        isPasswordVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(top: 2.0, left: 3.0),
                      child: Icon(CupertinoIcons.lock_rotation_open, color: greyColor, size: 22),
                    ),
                    hintText: "Mot de passe",
                    hintStyle: const TextStyle(color: Colors.black, fontSize: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("Mot de passe oublié ?", style: TextStyle(color: Colors.black)),
                  ],
                ),
                const SizedBox(height: 35),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formstate.currentState!.validate()) {
                            await login();
                          } else {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.error,
                              title: 'Erreur',
                              text: 'Entrez votre e-mail et votre mot de passe',
                            );
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(mainColor),
                          padding: WidgetStateProperty.all(
                              isLoading ? const EdgeInsets.all(10) : const EdgeInsets.all(13)),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                        ),
                        child: isLoading
                            ? Center(
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                  color: whiteColor,
                                  size: 32,
                                ),
                              )
                            : const Text(
                                "Connecter",
                                style: TextStyle(
                                    fontSize: 16, color: whiteColor, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}