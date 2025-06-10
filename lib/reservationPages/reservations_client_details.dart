// AcceptedReservationDetailPage.dart
// Affichage de la première photo issue de `images_urls` stockée dans la réservation
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:amira_app/stripe_payment/payment_manager.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../shared/colors.dart';

class AcceptedReservationDetailPage extends StatefulWidget {
  final Map<String, dynamic> reservation;
  final String reservationId;

  const AcceptedReservationDetailPage({
    super.key,
    required this.reservation,
    required this.reservationId,
  });

  @override
  _AcceptedReservationDetailPageState createState() =>
      _AcceptedReservationDetailPageState();
}

class _AcceptedReservationDetailPageState
    extends State<AcceptedReservationDetailPage> {
  List<LatLng> _routePoints = [];
  bool _loadingRoute = true;
  late LatLng _start, _end;
  LatLng? _transporteurPosition;
  StreamSubscription<DocumentSnapshot>? _positionSub;
  bool _isPaying = false;
  late bool _isPaid;

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey =
        'pk_test_51RU8444GAfRAvD2cn3QImq5eVJFXo7buYFBaXBIVE6F1tSJu3oiQ8lQAk1qIspU7CcLxr7mhHQmrqJU7m2cdnLPS0076AnnXbb';
    Stripe.instance.applySettings();

    _isPaid = (widget.reservation['is_Paied'] as String?)?.toLowerCase() == 'oui';

    final GeoPoint gp = widget.reservation['pickup'] as GeoPoint;
    final GeoPoint gd = widget.reservation['dropoff'] as GeoPoint;
    _start = LatLng(gp.latitude, gp.longitude);
    _end = LatLng(gd.latitude, gd.longitude);

    _fetchRoute();
    if (_isPaid) _listenToTransporteurPosition();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  void _listenToTransporteurPosition() {
    final transporteurId = widget.reservation['chauffeur_id'];
    _positionSub = FirebaseFirestore.instance
        .collection('positions_transporteurs')
        .doc(transporteurId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data != null && data['lat'] != null && data['lng'] != null) {
        setState(() {
          _transporteurPosition = LatLng(data['lat'], data['lng']);
        });
      }
    });
  }

  Future<void> _fetchRoute() async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${_start.longitude},${_start.latitude};'
          '${_end.longitude},${_end.latitude}'
          '?overview=full&geometries=geojson';
      final resp = await Dio().get(url);
      final coords = resp.data['routes'][0]['geometry']['coordinates'] as List;
      final pts = coords
          .map((c) => LatLng((c as List)[1] as double, c[0] as double))
          .toList();
      setState(() => _routePoints = pts);
    } catch (_) {
    } finally {
      setState(() => _loadingRoute = false);
    }
  }

  Future<void> _handlePayment() async {
    if (_isPaid || _isPaying) return;
    setState(() => _isPaying = true);
    final priceStr = widget.reservation['prix'] as String? ?? '0';
    final amountEuro = int.tryParse(priceStr) ?? 0;
    print("Raw prix value: $priceStr, Parsed amountEuro: $amountEuro");

    // Convert to cents for Stripe (e.g., 200 EUR = 20000 cents)
    final amountInCents = amountEuro > 0 ? amountEuro * 100 : 20000; // Default to 200 EUR if invalid

    try {
      print("Attempting payment with amount: $amountInCents cents");
      // Assume PaymentManager.makePayment returns the payment intent ID or a success response
      final paymentResult = await PaymentManager.makePayment(amountInCents, 'eur');
      print("Payment result: paymentResult");

      await FirebaseFirestore.instance
          .collection('reservation')
          .doc(widget.reservationId)
          .update({'is_Paied': 'oui'});

      await FirebaseFirestore.instance
          .collection('notificationsTransporteur')
          .add({
        'client_id': FirebaseAuth.instance.currentUser!.uid,
        'transporteur_id': widget.reservation['chauffeur_id'],
        'titre': 'Paiement reçu',
        'contenu': 'Votre paiement a bien été reçu.',
        'date': Timestamp.now(),
      });

      setState(() => _isPaid = true);
      _listenToTransporteurPosition();

      Get.snackbar('Succès', 'Paiement effectué avec succès !');
    } catch (e) {
      print("Payment error details: $e");
      Get.snackbar('Erreur', 'Erreur paiement ! Détails : $e');
    } finally {
      setState(() => _isPaying = false);
    }
  }

  Future<void> _showFeedbackDialog() async {
    int starCount = 0;
    final commentCtrl = TextEditingController();
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data()!;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSB) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Laisser un feedback',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800)),
                  const SizedBox(height: 16),
                  RatingBar.builder(
                    initialRating: starCount.toDouble(),
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 36,
                    unratedColor: Colors.grey.shade300,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                    itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      setStateSB(() => starCount = rating.toInt());
                    },
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Votre commentaire',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: mainColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Annuler', style: TextStyle(color: mainColor)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: starCount == 0
                              ? null
                              : () async {
                                  await FirebaseFirestore.instance
                                      .collection('rates')
                                      .add({
                                    'transporteur_id': widget.reservation['chauffeur_id'],
                                    'client_id': user.uid,
                                    'client_nom': userData['nom'] ?? '',
                                    'client_prenom': userData['prenom'] ?? '',
                                    'client_image': userData['url_image'] ?? '',
                                    'commentaire': commentCtrl.text,
                                    'rate': starCount,
                                    'date': Timestamp.now(),
                                  });
                                  Navigator.pop(ctx);
                                  Get.snackbar('Merci', 'Votre feedback a été envoyé.');
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Envoyer',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailBox(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(children: [
          Icon(icon, color: mainColor),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    // Récupère la liste des URLs d'images depuis la réservation
    final images = (widget.reservation['images_urls'] as List<dynamic>?)?.cast<String>() ?? [];

    // Première photo ou placeholder
    final firstImage = images.isNotEmpty
        ? images.first
        : 'assets/images/placeholder_car.png';

    final center = LatLng(
      (_start.latitude + _end.latitude) / 2,
      (_start.longitude + _end.longitude) / 2,
    );
    final dateStr = widget.reservation['date'] as String? ?? '';
    final timeStr = widget.reservation['heure'] as String? ?? '';
    final prix = widget.reservation['prix'] as String? ?? '';
    final depart = widget.reservation['depart'] as String? ?? '';
    final dest = widget.reservation['destination'] as String? ?? '';
    final carName = widget.reservation['car_nom'] as String? ?? '';
    final carPrice = widget.reservation['car_prix_jour'] as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Détails de la réservation",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          _isPaid
              ? const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: FaIcon(FontAwesomeIcons.checkCircle, color: Colors.green),
                )
              : const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: FaIcon(FontAwesomeIcons.timesCircle, color: Colors.red),
                ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 11),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                if (!_loadingRoute)
                  PolylineLayer(polylines: [
                    Polyline(
                        points: _routePoints,
                        color: mainColor,
                        strokeWidth: 4),
                  ]),
                MarkerLayer(markers: [
                  Marker(
                    child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                    point: _start,
                    width: 40,
                    height: 40,
                  ),
                  Marker(
                    child: const Icon(Icons.flag, color: Colors.red, size: 40),
                    point: _end,
                    width: 40,
                    height: 40,
                  ),
                  if (_isPaid && _transporteurPosition != null)
                    Marker(
                      child: const Icon(Icons.local_shipping, color: Colors.blue, size: 40),
                      point: _transporteurPosition!,
                      width: 40,
                      height: 40,
                    ),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: mainColor, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Image(
                        image: firstImage.startsWith('http')
                            ? NetworkImage(firstImage)
                            : AssetImage(firstImage) as ImageProvider,
                        width: 100,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(carName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("$carPrice €/jour",
                              style: const TextStyle(fontSize: 14, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                children: [
                  _detailBox(Icons.location_on, "Départ", depart),
                  const SizedBox(height: 8),
                  _detailBox(Icons.flag, "Arrivée", dest),
                  const SizedBox(height: 8),
                  _detailBox(Icons.calendar_today, "Date & heure", "$dateStr à $timeStr"),
                  const SizedBox(height: 22),
                  _isPaid
                      ? SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _showFeedbackDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text("Envoyer un feedback",
                                style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isPaying ? null : _handlePayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isPaying
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Payer",
                                    style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}