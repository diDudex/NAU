import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Definimos la clase LatLngTween personalizada para la interpolación
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
      : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    // Interpolamos entre el punto de inicio y el final
    final lat = (begin?.latitude ?? 0.0) + ((end?.latitude ?? 0.0) - (begin?.latitude ?? 0.0)) * t;
    final lng = (begin?.longitude ?? 0.0) + ((end?.longitude ?? 0.0) - (begin?.longitude ?? 0.0)) * t;
    return LatLng(lat, lng);
  }
}

class MapadeRutas extends StatefulWidget {
  const MapadeRutas({super.key});

  @override
  _MapadeRutasState createState() => _MapadeRutasState();
}

class _MapadeRutasState extends State<MapadeRutas> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  List<LatLng> _routePoints = [];
  List<Marker> _markers = [];
  late AnimationController _animationController;
  late Animation<LatLng> _busAnimation;
  late LatLng _busPosition;
  bool _isAnimationRunning = false;

  @override
  void initState() {
    super.initState();

    // Inicializa el controlador de la animación
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    );

    // Carga las rutas desde Firestore
    _loadRoutes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    // Obtiene las rutas desde Firestore
    FirebaseFirestore.instance.collection('busRoutes').snapshots().listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final route = data['polyline'] as List;
        final List<LatLng> routePoints = route
            .map((point) => LatLng(point['lat'], point['lng']))
            .toList();

        setState(() {
          _routePoints = routePoints;
          _markers.add(Marker(
            markerId: MarkerId(doc.id),
            position: _routePoints.first, // Marca el inicio de la ruta
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ));

          // Inicializa la animación para el autobús
          _busPosition = _routePoints.first;
          _busAnimation = LatLngTween(
            begin: _routePoints.first,
            end: _routePoints.last,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.linear,
            ),
          );

          // Comienza la animación
          _animationController.forward();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _routePoints.isNotEmpty ? _routePoints.first : LatLng(0.0, 0.0),
        zoom: 12,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
      },
      markers: Set.from(_markers),
      polylines: {
        Polyline(
          polylineId: PolylineId('route'),
          points: _routePoints,
          color: Colors.blue,
          width: 5,
        ),
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onCameraMove: (cameraPosition) {
        // Detén la animación si el mapa es movido manualmente
        if (_isAnimationRunning) {
          _animationController.stop();
        }
      },
      onTap: (_) {
        // Reinicia la animación cuando el usuario toque el mapa
        if (_isAnimationRunning) {
          _animationController.repeat();
        }
      },
    );
  }
}
