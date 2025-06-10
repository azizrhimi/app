import 'package:amira_app/registerScreens/register_client.dart';
import 'package:amira_app/registerScreens/register_transporteur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../shared/colors.dart';

class ChoisirRole extends StatelessWidget {
  const ChoisirRole({super.key});

  void onClientPressed() {
    Get.to(() => const RegisterPage(), transition: Transition.downToUp);
  }

  void onTransporteurPressed() {
    Get.to(() => const RegisterTransporteur(), transition: Transition.downToUp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🖼️ Illustration SVG
                SvgPicture.asset(
                  'assets/images/role.svg',
                  height: 170,
                ),
                const SizedBox(height: 30),

                // 📝 Texte principal
                const Text(
                  "S'inscrire en tant que",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Choisissez votre rôle pour commencer l'expérience.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // 👤 Bouton Client
                ElevatedButton.icon(
                  onPressed: onClientPressed,
                  icon: const Icon(Icons.person_outline, color: Colors.white),
                  label: const Text("Client", style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 🚚 Bouton Transporteur
                ElevatedButton.icon(
                  onPressed: onTransporteurPressed,
                  icon: const Icon(Icons.local_shipping_outlined, color: Colors.white),
                  label: const Text("Transporteur", style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
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
