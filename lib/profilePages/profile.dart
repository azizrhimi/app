import 'package:amira_app/Screens/transporteur_feedback.dart';
import 'package:amira_app/profilePages/editprofile.dart';
import 'package:amira_app/profilePages/profilecard.dart';
import 'package:amira_app/registerScreens/choix_register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map userData = {};
  bool isLoading = true;

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();

      userData = snapshot.data()!;
    } catch (e) {
      print(e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: LoadingAnimationWidget.discreteCircle(
                size: 32,
                color: const Color.fromARGB(255, 16, 16, 16),
                secondRingColor: Colors.indigo,
                thirdRingColor: Colors.pink.shade400,
              ),
            ),
          )
        : Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: const Text(
                "Profile",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
              ),
              centerTitle: true,
              elevation: 0,
              actions: [
                userData['role'] == 'transporteur'
                    ? IconButton(
                        icon: SvgPicture.asset(
                          "assets/images/feedback.svg",
                          height: 36,
                          width: 36,
                        ),
                        onPressed: () {
                          Get.to(() => TransporteurFeedBackPage(
                                uid: FirebaseAuth.instance.currentUser!.uid,
                              ));
                        },
                      )
                    : const SizedBox()
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(height: 170, color: Colors.white),
                      Positioned(
                        top: 30,
                        right: MediaQuery.of(context).size.width / 2 - 60,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              (userData['url_image'] != null &&
                                      userData['url_image']
                                          .toString()
                                          .isNotEmpty)
                                  ? NetworkImage(userData['url_image'])
                                      as ImageProvider
                                  : null,
                          child: (userData['url_image'] == null ||
                                  userData['url_image'].toString().isEmpty)
                              ? SvgPicture.asset(
                                  'assets/images/avatar_placeholder.svg',
                                  width: 90,
                                  height: 90,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userData['role'] == 'transporteur'
                        ? userData['chauffeur_nom']
                        : '${userData['nom']} ${userData['prenom']}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        const Gap(20),
                        _infoRow("Type", userData['role']),
                        const Gap(20),
                        _infoRow("Email", userData['email']),
                        const Gap(20),
                        Divider(thickness: 1, color: Colors.grey[200]),
                        const Gap(20),
                        ProfileSettingCard(
                          text: "Modifier votre profil",
                          icon: LineAwesomeIcons.user_edit_solid,
                          onPressed: () {
                            Get.to(() => const EditProfilePage());
                          },
                        ),
                        const Gap(20),
                        ProfileSettingCard(
                          text: "Obtenir l'aide",
                          icon: CupertinoIcons.question,
                          onPressed: () {},
                        ),
                        const Gap(20),
                        ProfileSettingCard(
                          text: "À propos de nous",
                          icon: CupertinoIcons.info,
                          onPressed: () {},
                        ),
                        const Gap(20),
                        ProfileSettingCard(
                          text: "Supprimer le compte",
                          icon: CupertinoIcons.delete,
                          onPressed: () {},
                        ),
                        const Gap(20),
                        ListTile(
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const ChoixRegister(),
                              ),
                              (route) => false,
                            );
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.blue.withOpacity(0.1),
                            ),
                            child: Icon(
                              LineAwesomeIcons.sign_in_alt_solid,
                              color: Colors.red[800],
                            ),
                          ),
                          title: Text(
                            "Déconnexion",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.red[800],
                            ),
                          ),
                          trailing: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.grey.withOpacity(0.1),
                            ),
                            child: const Icon(
                              LineAwesomeIcons.angle_right_solid,
                              color: Colors.black87,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 17, color: Colors.grey)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
