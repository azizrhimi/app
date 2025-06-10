import 'package:amira_app/chatPages/ClientsMessageriePage.dart';

import 'package:amira_app/reservationPages/ReservationTransporteur.dart';
import 'package:amira_app/Screens/transporteur_list.dart';
import 'package:amira_app/notificationsPages/notifications.dart';
import 'package:amira_app/reservationPages/reservation_client.dart';
import 'package:amira_app/shared/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../carPages/car_list.dart';
import '../profilePages/profile.dart';

class Screens extends StatefulWidget {
  const Screens({super.key});

  @override
  State<Screens> createState() => _ScreensState();
}

class _ScreensState extends State<Screens> {
  Map userData = {};
  bool isLoading = true;

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users') //client
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

  final PageController _pageController = PageController();

  int currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator(color: Colors.black)),
        )
        : Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(
              left: 25,
              right: 25,
              top: 4,
              bottom: 4,
            ),
            child: GNav(
              backgroundColor: Colors.white,
              gap: 10,
              color: Colors.grey,
              activeColor: mainColor,
              curve: Curves.decelerate,
              padding: const EdgeInsets.only(
                bottom: 10,
                left: 6,
                right: 6,
                top: 2,
              ),
              onTabChange: (index) {
                _pageController.jumpToPage(index);
                setState(() {
                  currentPage = index;
                });
              },
              tabs: [
                userData['role'] == 'transporteur'
                    ? GButton(
                      icon: LineAwesomeIcons.home_solid,
                      text: 'Reservations',
                    )
                    : GButton(
                      icon: LineAwesomeIcons.home_solid,
                      text: 'Transporteur',
                    ),
                userData['role'] == 'transporteur'
                    ? GButton(
                      icon: LineAwesomeIcons.comment,
                      text: 'Messagerie',
                    )
                    : GButton(icon: CupertinoIcons.bell, text: 'Notifications'),
                userData['role'] == 'transporteur'
                    ? GButton(icon: CupertinoIcons.car_fill, text: 'Cars')
                    : GButton(icon: Iconsax.reserve, text: 'Reservations'),
                GButton(icon: CupertinoIcons.person, text: 'Profile'),
              ],
            ),
          ),
          body: PageView(
            onPageChanged: (index) {},
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            children: [
              userData['role'] == 'transporteur'
                  ? const ReservationTransporteur()
                  : const TransporteurList(),
              userData['role'] == 'transporteur'
                  ? const ClientsMessageriePage()
                  : const NotificationsPage(),
              userData['role'] == 'transporteur'
                  ? CarListPage()
                  : AcceptedReservationsPage(),
              const Profile(),
            ],
          ),
        );
  }
}
