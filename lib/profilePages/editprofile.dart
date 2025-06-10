import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../shared/colors.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  DateTime? startDate;

  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final emailController = TextEditingController();
  final roleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      userData = doc.data() ?? {};

      // Remplissage des controllers
      final role = userData['role'] as String? ?? '';
      if (role == 'transporteur') {
        nomController.text = userData['chauffeur_nom'] as String? ?? '';
      } else {
        nomController.text = userData['nom'] as String? ?? '';
      }
      prenomController.text = userData['prenom'] as String? ?? '';
      emailController.text = userData['email'] as String? ?? '';
      roleController.text = role;

      final anniv = userData['anniversaire'] as String? ?? '';
      if (anniv.isNotEmpty) {
        startDate = DateFormat('MMMM d, y').parse(anniv);
      }
    } catch (e) {
      print("Erreur chargement profil: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    final isTransporteur = roleController.text == 'transporteur';

    final updates = <String, dynamic>{
      'prenom': prenomController.text,
      'email': emailController.text,
      'role': roleController.text,
      'anniversaire': startDate != null
          ? DateFormat('MMMM d, y').format(startDate!)
          : '',
    };

    if (isTransporteur) {
      updates['chauffeur_nom'] = nomController.text;
    } else {
      updates['nom'] = nomController.text;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update(updates);

    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: 'Profil mis à jour avec succès !',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTransporteur = roleController.text == 'transporteur';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Modifier Profil",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.discreteCircle(
                size: 32,
                color: Colors.black,
                secondRingColor: Colors.indigo,
                thirdRingColor: Colors.pink.shade400,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: (userData['url_image'] != null &&
                              (userData['url_image'] as String).isNotEmpty)
                          ? NetworkImage(userData['url_image'] as String)
                          : null,
                      child: (userData['url_image'] == null ||
                              (userData['url_image'] as String).isEmpty)
                          ? SvgPicture.asset(
                              'assets/images/avatar_placeholder.svg',
                              width: 90,
                              height: 90,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTransporteur ? 'Nom du chauffeur' : 'Nom',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nomController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: isTransporteur
                                ? 'Entrez le nom du chauffeur'
                                : 'Entrez votre nom',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: mainColor, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isTransporteur) _buildField("Prénom", prenomController),
                  _buildField("Email", emailController),
                  _buildField("Rôle", roleController),
                  const SizedBox(height: 10),
                  const Text("Date de naissance", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => startDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Text(
                        startDate != null
                            ? "${startDate!.day}/${startDate!.month}/${startDate!.year}"
                            : "Choisir une date",
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text(
                      "Mettre à jour le profil",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: "Entrez $label",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: mainColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
