import 'package:amira_app/registerScreens/choix_role.dart';
import 'package:amira_app/registerScreens/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../shared/colors.dart';

class ChoixRegister extends StatelessWidget {
  const ChoixRegister({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🖼️ Image ou Logo
                SvgPicture.asset(
                  "assets/images/welcome.svg",
                  height: 160,
                ),
                const SizedBox(height: 30),

                // 📣 Bienvenue
                const Text(
                  "Bienvenue !",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Connecte-toi ou crée un compte pour continuer.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                ),
                const SizedBox(height: 40),

                // 🔐 Bouton Connexion
                ElevatedButton(
                  onPressed: () {
                    Get.to(() => const LoginPage(), transition: Transition.rightToLeft);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 4,
                    backgroundColor: mainColor,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "J'ai un compte",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 18),

                // ➕ Bouton Création de compte
                OutlinedButton(
                  onPressed: () {
                    Get.to(() => const ChoisirRole(), transition: Transition.downToUp);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: mainColor),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Créer un compte",
                    style: TextStyle(fontSize: 16, color: mainColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
