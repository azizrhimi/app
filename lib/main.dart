import 'package:amira_app/Screens/screens.dart';
import 'package:amira_app/registerScreens/choix_register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:amira_app/admin/admin_dashboard.dart';
import 'package:amira_app/registerScreens/login.dart';
import 'package:amira_app/admin/admin_users.dart';
import 'package:amira_app/admin/admin_reclamations.dart';
import 'package:amira_app/admin/admin_reservations.dart';
import 'package:amira_app/admin/admin_cars.dart';
import 'package:amira_app/admin/admin_feedbacks.dart';
import 'package:amira_app/notificationsPages/notifications.dart'; // Pour les clients
import 'package:amira_app/notificationsPages/notificationsTransporteur.dart'; // Pour les transporteurs
import 'package:amira_app/notificationsPages/NotificationsAdminPage.dart'; // Pour les admins
import 'package:amira_app/complimentScreens/AjouterReclamation.dart'; // Pour ajouter une réclamation

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        print('Génération de la route : ${settings.name}');
        return null;
      },
      getPages: [
        GetPage(name: '/home', page: () {
          print('Redirection vers /home, utilisateur connecté : ${FirebaseAuth.instance.currentUser != null}');
          return FirebaseAuth.instance.currentUser == null
              ? const ChoixRegister()
              : const Screens();
        }),
        GetPage(name: '/adminDashboard', page: () => const AdminDashboard()),
        //GetPage(name: '/simpleHome', page: () => const SimpleHomePage()),
        GetPage(name: '/login', page: () {
          print('Redirection vers /login');
          return const LoginPage();
        }),
        GetPage(name: '/adminUsers', page: () => const AdminUsersPage()),
        GetPage(name: '/adminReclamations', page: () => const AdminReclamationsPage()),
        GetPage(name: '/adminReservations', page: () => const AdminReservationsPage()),
        GetPage(name: '/adminCars', page: () => const AdminCarsPage()),
        GetPage(name: '/adminFeedbacks', page: () => const AdminFeedbacksPage()),
        GetPage(name: '/notifications', page: () => const NotificationsPage()),
        GetPage(name: '/notificationsTransporteur', page: () => const NotificationTrasporteur()),
        GetPage(name: '/notificationsAdmin', page: () => const NotificationsAdminPage()),
        GetPage(name: '/addReclamation', page: () => const AjouterReclamation()),
      ],
    );
  }
}