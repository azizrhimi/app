// ReservationActionPage.dart
// ReservationActionPage mise à jour pour activer le tracking temps réel
// et affichage dynamique de l'image du véhicule.
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:geolocator/geolocator.dart';

class ReservationActionPage extends StatefulWidget {
  final Map<String, dynamic> reservationData;
  final String reservationId;

  const ReservationActionPage({
    super.key,
    required this.reservationData,
    required this.reservationId,
  });

  @override
  State<ReservationActionPage> createState() => _ReservationActionPageState();
}

class _ReservationActionPageState extends State<ReservationActionPage> {
  String? status;
  bool _isPaid = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    status = widget.reservationData['status'] as String?;
    final isPaidStr = widget.reservationData['is_Paied'] as String?;
    _isPaid = isPaidStr?.toLowerCase() == 'oui';
  }

  Future<void> _handleAction({required bool accepted}) async {
    final chauffeur = FirebaseAuth.instance.currentUser;
    if (chauffeur == null) return;

    final clientId = widget.reservationData['client_id'] as String? ?? '';
    final chauffeurName =
        widget.reservationData['chauffeur_name'] as String? ??
            'Transporteur';
    final newStatus = accepted ? "acceptée" : "refusée";

    await FirebaseFirestore.instance
        .collection("reservation")
        .doc(widget.reservationId)
        .update({"status": newStatus});

    await FirebaseFirestore.instance.collection("notifications").add({
      "client_id": clientId,
      "transporteur_id": chauffeur.uid,
      "titre": accepted ? "Réservation acceptée" : "Réservation refusée",
      "contenu": accepted
          ? "$chauffeurName a accepté votre réservation."
          : "$chauffeurName a refusé votre réservation.",
      "date": Timestamp.now(),
    });

    setState(() => status = newStatus);

    await QuickAlert.show(
      context: context,
      type: accepted ? QuickAlertType.success : QuickAlertType.error,
      title: accepted ? "Succès" : "Refusée",
      text: accepted
          ? "Réservation confirmée avec succès."
          : "Réservation rejetée avec succès.",
    );
  }

  Future<void> _startLiveTracking() async {
    final transporteurId = FirebaseAuth.instance.currentUser!.uid;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      FirebaseFirestore.instance
          .collection('positions_transporteurs')
          .doc(transporteurId)
          .set({
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });

    Get.snackbar("Tracking activé",
        "Votre position est maintenant visible par le client.",
        snackPosition: SnackPosition.TOP);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Timestamp ts =
        widget.reservationData['datetime'] as Timestamp;
    final date = ts.toDate();
    final formattedDate =
        DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(date);

    final carImage = widget.reservationData['car_image']
            as String? ??
        'assets/images/placeholder_car.png';
    final carNom =
        widget.reservationData['car_nom'] as String? ?? '';
    final carPrixJour =
        widget.reservationData['car_prix_jour'] as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text("Détails Réservation",
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 19)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6FD),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(12),
                          child: carImage.startsWith('http')
                              ? Image.network(
                                  carImage,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/images/placeholder_car.png',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(carNom,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                  "$carPrixJour €/jour",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color:
                                          Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                        "Client : ${widget.reservationData['client_nom'] ?? ''} ${widget.reservationData['client_prenom'] ?? ''}",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                "De : ${widget.reservationData['depart']}")),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.flag,
                            color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                "A : ${widget.reservationData['destination']}")),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.directions_car,
                            color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(
                            "Véhicule : ${widget.reservationData['type_vehicule']}"),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.luggage,
                            color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(
                            "Bagage : ${widget.reservationData['type_bagage']}"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.attach_money,
                            color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                            "Prix proposé : ${widget.reservationData['prix']} €",
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(formattedDate,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black45)),
                    ),
                    const SizedBox(height: 16),
                    if (status == null ||
                        status == 'en_attente')
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(
                                Icons.check_circle,
                                size: 18),
                            label:
                                const Text("Confirmer"),
                            style: ElevatedButton.styleFrom(
                              foregroundColor:
                                  Colors.white,
                              backgroundColor:
                                  Colors.green,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        30),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 14),
                            ),
                            onPressed: () =>
                                _handleAction(
                                    accepted: true),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(
                                Icons.cancel,
                                size: 18),
                            label:
                                const Text("Rejeter"),
                            style: ElevatedButton.styleFrom(
                              foregroundColor:
                                  Colors.white,
                              backgroundColor:
                                  Colors.red,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        30),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 14),
                            ),
                            onPressed: () =>
                                _handleAction(
                                    accepted: false),
                          ),
                        ],
                      )
                    else if (status == 'acceptée' &&
                        _isPaid)
                      Center(
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              _startLiveTracking,
                          icon: const Icon(
                              Icons.play_arrow),
                          label: const Text(
                              "Commencer le trajet"),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.indigo,
                            foregroundColor:
                                Colors.white,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      30),
                            ),
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 14),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Chip(
                          label: Text(
                            "Réservation $status",
                            style: TextStyle(
                              color: status ==
                                      "acceptée"
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          backgroundColor: status ==
                                  "acceptée"
                              ? Colors.green[50]
                              : Colors.red[50],
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
