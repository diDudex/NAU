import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nau/screens_driver/modulos/control_panel.dart';
import 'package:nau/screens_driver/modulos/route_info_card.dart';
import 'package:nau/screens_driver/modulos/stat_card.dart';
import 'package:nau/widgets/mapa.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

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
  String? _assignedBusId;
  String? _routeName;
  String? _busNumber;
  StreamSubscription<DocumentSnapshot>? _driverSubscription;
  StreamSubscription<Position>? _positionStream;
  int _passengersToday = 0;
  double _todayEarnings = 0;
  double _rating = 4.8;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadDriverData();
  }

  @override
  void dispose() {
    _driverSubscription?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    final driverId = FirebaseAuth.instance.currentUser?.uid;
    if (driverId == null) return;

    // Configurar listener en tiempo real para datos del conductor
    _driverSubscription = FirebaseFirestore.instance
        .collection('Drivers')
        .doc(driverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          _assignedBusId = data['busid'];
          _passengersToday = data['passengersToday'] ?? 0;
          _todayEarnings = data['todayEarnings']?.toDouble() ?? 0;
          _rating = data['rating']?.toDouble() ?? 4.8;
        });
        _loadRouteAndBusInfo();
      }
    });
  }

  Future<void> _loadRouteAndBusInfo() async {
    if (_assignedBusId != null) {
      final busDoc = await FirebaseFirestore.instance
          .collection('Bus')
          .doc(_assignedBusId)
          .get();
      if (busDoc.exists) {
        setState(() {
          _busNumber = busDoc.data()?['numBus'];
          _assignedRouteId = busDoc.data()?['rutasid'];
        });
      }
    }

    if (_assignedRouteId != null) {
      final routeDoc = await FirebaseFirestore.instance
          .collection('Rutas')
          .doc(_assignedRouteId)
          .get();
      if (routeDoc.exists) {
        setState(() {
          _routeName = routeDoc.data()?['nombre'];
        });
      }
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
      // Obtener posición inicial
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Configurar actualización continua de posición
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Actualizar cada 10 metros
        ),
      ).listen((Position position) {
        _updateDriverLocation(position);
        setState(() => _currentPosition = position);
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _updateDriverLocation(Position position) async {
    final driverId = FirebaseAuth.instance.currentUser?.uid;
    if (driverId == null || _assignedBusId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('Bus')
          .doc(_assignedBusId)
          .update({
        'ubicacion': {
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      });
    } catch (e) {
      print('Error actualizando ubicación: $e');
    }
  }

  Future<void> _toggleTripStatus() async {
    final driverId = FirebaseAuth.instance.currentUser?.uid;
    if (driverId == null || _assignedBusId == null) return;

    final newStatus = !_isOnTrip;

    try {
      // Actualizar estado en Firestore
      await FirebaseFirestore.instance
          .collection('buses')
          .doc(_assignedBusId)
          .update({
        'estado': newStatus
            ? 'Activo'
            : 'inactivo', // Cambia a "Activo" al iniciar viaje
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Actualizar estado local
      setState(() {
        _isOnTrip = newStatus;
        if (_isOnTrip) {
          _tripStartTime = DateTime.now();
          _passengersCount = 0;
        } else {
          _tripStartTime = null;
          // Guardar estadísticas al finalizar el viaje
          _saveTripStats();
        }
      });
    } catch (e) {
      print('Error cambiando estado de viaje: $e');
    }
  }

  Future<void> _saveTripStats() async {
    final driverId = FirebaseAuth.instance.currentUser?.uid;
    if (driverId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .update({
        'passengersToday': FieldValue.increment(_passengersCount),
        'todayEarnings':
            FieldValue.increment(_passengersCount * 10), // $10 por pasajero
        'totalTrips': FieldValue.increment(1),
        'lastTripEnd': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error guardando estadísticas: $e');
    }
  }

  Future<void> _updatePassengersCount(int newCount) async {
    final driverId = FirebaseAuth.instance.currentUser?.uid;
    if (driverId == null || _assignedBusId == null) return;

    try {
      // Actualizar en bus
      await FirebaseFirestore.instance
          .collection('Bus')
          .doc(_assignedBusId)
          .update({
        'asientos': newCount,
      });

      // Actualizar en tiempo real si está en viaje
      if (_isOnTrip) {
        await FirebaseFirestore.instance
            .collection('trips')
            .doc('${driverId}_current')
            .set({
          'passengerCount': newCount,
          'lastUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      setState(() => _passengersCount = newCount);
    } catch (e) {
      print('Error actualizando pasajeros: $e');
    }
  }

  void _incrementPassengers() {
    _updatePassengersCount(_passengersCount + 1);
  }

  void _decrementPassengers() {
    if (_passengersCount > 0) {
      _updatePassengersCount(_passengersCount - 1);
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
                // Mapa en la parte superior
                const Expanded(
                  flex: 2,
                  child: const MapaScreen(),
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
                          routeName: _routeName ?? 'Sin ruta asignada',
                          schedule:
                              '7:00 AM - 3:00 PM', // Podrías obtener esto de la ruta
                          busNumber: _busNumber ?? '--',
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

                // Marcar y Desmarcar asientos diponibles
                // StreamBuilder para la lista de asientos
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: _assignedBusId != null
                        ? FirebaseFirestore.instance
                            .collection('Bus')
                            .doc(_assignedBusId)
                            .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.data() == null) {
                        return const Center(
                            child: Text('No se encontraron datos'));
                      }

                      // Procesar datos y actualizar estado
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final seatsData =
                          data['asientos'] as Map<String, dynamic>? ?? {};

                      // Actualizar el mapa de disponibilidad
                      seatAvailability = {
                        for (var entry in seatsData.entries)
                          int.parse(entry.key): entry.value as bool
                      };

                      // Asegurar que tenemos todos los asientos (1-24)
                      for (int i = 1; i <= 24; i++) {
                        seatAvailability.putIfAbsent(i, () => false);
                      }

                      return _buildBusLayout();
                    },
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
            value: '$_passengersToday',
            label: 'Pasajeros hoy',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.attach_money,
            value: _currencyFormat.format(_todayEarnings),
            label: 'Ingresos hoy',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.star,
            value: _rating.toStringAsFixed(1),
            label: 'Calificación',
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  // Método para construir el layout del autobús
  // Este método crea la estructura visual del autobús con los asientos
  Widget _buildBusLayout() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Column(
        children: [
          // Cabina del conductor
          Container(
            height: 40,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.airline_seat_recline_normal,
                    color: Colors.grey.shade600, size: 24),
                const SizedBox(width: 8),
                Text(
                  'CONDUCTOR',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Asientos del autobús con pasillo central
          Expanded(
            child: ListView.builder(
              itemCount: 6, // 6 filas (4 asientos por fila = 24 total)
              itemBuilder: (context, rowIndex) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lado izquierdo (2 asientos)
                      Row(
                        children: [
                          _buildSeat((rowIndex * 4) + 1),
                          const SizedBox(width: 8),
                          _buildSeat((rowIndex * 4) + 2),
                        ],
                      ),

                      // Pasillo
                      SizedBox(
                        width: 50,
                        height: 45,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 2,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey.shade300,
                                    Colors.grey.shade500,
                                    Colors.grey.shade300,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lado derecho (2 asientos)
                      Row(
                        children: [
                          _buildSeat((rowIndex * 4) + 3),
                          const SizedBox(width: 8),
                          _buildSeat((rowIndex * 4) + 4),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<int> selectedSeats = [];
  Map<int, bool> seatAvailability = {};

  Widget _buildSeat(int seatNumber) {
    final isOccupied =
        seatAvailability[seatNumber] == true; // true significa ocupado
    final isSelected = selectedSeats.contains(seatNumber);

    return GestureDetector(
      onTap: isOccupied
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  selectedSeats.remove(seatNumber);
                } else {
                  selectedSeats.add(seatNumber);
                }
              });
            },
      child: Container(
        width: 55,
        height: 55,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.shade600
              : isOccupied
                  ? Colors.grey.shade400
                  : Colors.white,
          border: Border.all(
            color: isSelected
                ? Colors.blue.shade800
                : isOccupied
                    ? Colors.grey.shade600
                    : Colors.grey.shade600,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Número del asiento
            Center(
              child: Text(
                seatNumber.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : isOccupied
                          ? Colors.grey.shade600
                          : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
