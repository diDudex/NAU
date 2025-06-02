import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // Asegúrate de importar el paquete de Firestore

class MapaScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedBus;

  const MapaScreen({super.key, this.selectedBus});

  @override
  _MapaScreenState createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  GoogleMapController? _mapController;
  LatLng _initialPosition =
      const LatLng(25.367269591435303, -108.15921351313591);
  Set<Polyline> _polylines = {};
  bool _loadingRoute = false;

  // Reemplaza con tu API key de Google Maps
  static const String _googleMapsApiKey =
      'AIzaSyCnafhmFze96Dvw5-jPI29MdhiZWJaO45U';
  static const String _directionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
    _setupBusRoute();
  }

  Future<void> _obtenerUbicacionActual() async {
    var permiso = await Permission.location.request();

    if (permiso.isGranted) {
      Position posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Solo mueve la cámara a la ubicación actual, no agrega marcador
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(posicion.latitude, posicion.longitude),
        ),
      );
    } else {
      print("Permiso denegado");
    }
  }

  Future<void> _setupBusRoute() async {
    if (widget.selectedBus == null) return;

    setState(() {
      _loadingRoute = true;
    });

    // Coordenadas reales del autobús
    final LatLng origin = const LatLng(25.367269591435303, -108.15921351313591);
    final LatLng destination = const LatLng(25.461071231845242, -108.08470040559769);

    // Waypoints proporcionados
    final busDoc = await FirebaseFirestore.instance
        .collection('busRoutes')
        .doc(widget.selectedBus!['id'])
        .get();

    if (busDoc.exists) {
      final routeData = busDoc.data() as Map<String, dynamic>;

      // Obtener waypoints desde Firestore
      List<LatLng> waypoints = [];
      if (routeData['waypoints'] != null) {
        waypoints = (routeData['waypoints'] as List<dynamic>).map((point) {
          return LatLng(point['lat'], point['lng']);
        }).toList();
      }

      // Obtener ruta de Directions API con waypoints
      final List<LatLng> routePoints =
          await _getRoutePoints(origin, destination, waypoints);

      if (routePoints.isNotEmpty) {
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('bus_route'),
              points: routePoints,
              color: Colors.blue,
              width: 5,
            ),
          );

          // Centrar el mapa para mostrar toda la ruta
          _initialPosition = LatLng(
            (origin.latitude + destination.latitude) / 2,
            (origin.longitude + destination.longitude) / 2,
          );
        });

        // Ajustar la vista para mostrar toda la ruta
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            _boundsFromLatLngList(routePoints),
            100.0,
          ),
        );
      }

      setState(() {
        _loadingRoute = false;
      });
    }
  }

  Future<List<LatLng>> _getRoutePoints(
      LatLng origin, LatLng destination, List<LatLng> waypoints) async {
    // Construir cadena de waypoints para la URL
    String waypointsParam = '';
    if (waypoints.isNotEmpty) {
      waypointsParam =
          '&waypoints=optimize:true|${waypoints.map((point) => '${point.latitude},${point.longitude}').join('|')}';
    }

    final url = Uri.parse(
      '$_directionsBaseUrl?'
      'origin=${origin.latitude},${origin.longitude}&'
      'destination=${destination.latitude},${destination.longitude}'
      '$waypointsParam&'
      'key=$_googleMapsApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          // Decodificar puntos de la ruta
          final points = data['routes'][0]['overview_polyline']['points'];
          return _decodePolyline(points);
        }
      }
      return [
        origin,
        ...waypoints,
        destination
      ]; // Fallback a línea recta con waypoints
    } catch (e) {
      print('Error obteniendo ruta: $e');
      return [
        origin,
        ...waypoints,
        destination
      ]; // Fallback a línea recta con waypoints
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedBus?['nombre'] ?? 'Mapa de Autobús',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12,
            ),
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          if (_loadingRoute)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'route_button',
            onPressed: () {
              if (_polylines.isNotEmpty) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    _boundsFromLatLngList(_polylines.first.points),
                    100.0,
                  ),
                );
              }
            },
            child: const Icon(Icons.alt_route),
            mini: true,
          ),
        ],
      ),
    );
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }
}
