import 'package:flutter/material.dart';
import 'package:nau/pages/mapa/mapade_rutas.dart';
import 'package:nau/screens_driver/modulos/control_panel.dart';
import 'package:nau/screens_driver/modulos/route_info_card.dart';
import 'package:nau/screens_driver/modulos/stat_card.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class DriverHomeScreen extends StatefulWidget {
  final String uid;
  const DriverHomeScreen({super.key, required this.uid});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isLoadingLocation = true;
  Position? _currentPosition;
  bool _isOnTrip = false;
  DateTime? _tripStartTime;
  int _passengersCount = 0;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');
  String? _assignedRouteId;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadAssignedRoute();
  }

  Future<void> _loadAssignedRoute() async {
    final driverId = FirebaseAuth.instance.currentUser?.uid;
    if (driverId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .get();

      if (snapshot.exists) {
        setState(() {
          _assignedRouteId = snapshot.data()?['assignedRouteId'];
        });
      }
    } catch (e) {
      print('Error cargando ruta asignada: $e');
    }
  }

  Future<void> _initLocation() async {
    setState(() => _isLoadingLocation = true);

    final status = await Permission.location.request();
    if (!status.isGranted) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _toggleTripStatus() {
    setState(() {
      _isOnTrip = !_isOnTrip;
      if (_isOnTrip) {
        _tripStartTime = DateTime.now();
        _passengersCount = 0;
      } else {
        _tripStartTime = null;
      }
    });
  }

  void _incrementPassengers() {
    setState(() => _passengersCount++);
  }

  void _decrementPassengers() {
    if (_passengersCount > 0) {
      setState(() => _passengersCount--);
    }
  }

  String _getTripDuration() {
    if (_tripStartTime == null) return '0h 0m';
    final duration = DateTime.now().difference(_tripStartTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Conductor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Mapa en la parte superior (sin cambios)
                Expanded(
                  flex: 2,
                  child: MapadeRutas(),
                ),
                
                // Contenido modularizado
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        RouteInfoCard(
                          isOnTrip: _isOnTrip,
                          routeName: 'Ruta 5 - Centro a Zona Norte',
                          schedule: '7:00 AM - 3:00 PM',
                          busNumber: 'R5-22',
                          tripDuration: _getTripDuration(),
                        ),
                        const SizedBox(height: 20),
                        ControlPanel(
                          isOnTrip: _isOnTrip,
                          onToggleTrip: _toggleTripStatus,
                          onIncrement: _incrementPassengers,
                          onDecrement: _decrementPassengers,
                          passengersCount: _passengersCount,
                        ),
                        const SizedBox(height: 20),
                        _buildQuickStats(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.people,
            value: '2',
            label: 'Pasajeros hoy',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.attach_money,
            value: _currencyFormat.format(320),
            label: 'Ingresos hoy',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.star,
            value: '4.8',
            label: 'Calificación',
            color: Colors.amber,
          ),
        ),
      ],
    );
  }
}