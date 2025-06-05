import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapaScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedBus;
  final Position? currentPosition;

  const MapaScreen({
    super.key, 
    this.selectedBus,
    this.currentPosition,
  });

  @override
  _MapaScreenState createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  GoogleMapController? _mapController;
  late LatLng _initialPosition;
  Set<Polyline> _polylines = {};
  bool _loadingRoute = false;
  bool _showUserLocation = false;

  static const String _googleMapsApiKey = 'AIzaSyCnafhmFze96Dvw5-jPI29MdhiZWJaO45U';
  static const String _directionsBaseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  @override
  void initState() {
    super.initState();
    _initialPosition = widget.currentPosition != null 
      ? LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude)
      : const LatLng(25.367269591435303, -108.15921351313591);
    
    _setupBusRoute();
  }

  Future<void> _toggleUserLocation() async {
    if (!_showUserLocation) {
      final status = await Permission.location.request();
      if (status.isGranted) {
        try {
          final position = await Geolocator.getCurrentPosition();
          setState(() {
            _showUserLocation = true;
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude),
              ),
            );
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error obteniendo ubicación: $e')),
          );
        }
      }
    } else {
      setState(() {
        _showUserLocation = false;
      });
    }
  }

  Future<void> _setupBusRoute() async {
    if (widget.selectedBus == null || widget.selectedBus!['rutaid'] == null) return;

    setState(() => _loadingRoute = true);

    try {
      final routeDoc = await FirebaseFirestore.instance
          .collection('Rutas')
          .doc(widget.selectedBus!['rutaid'])
          .get();

      if (!routeDoc.exists) return;

      final routeData = routeDataWithDefaults(routeDoc.data()!);

      // 1. Intentar usar polylinePoints si existen
      if (routeData['polyline'] != null && routeData['polyline'].isNotEmpty) {
        final points = routeData['polyline'].map<LatLng>((p) => 
          LatLng(p['lat'], p['lng'])
        ).toList();

        _updateMapWithRoute(points);
        setState(() => _loadingRoute = false);
        return;
      }

      // 2. Si no hay polyline, usar la API de direcciones
      final origin = LatLng(
        routeData['origin']['lat'], 
        routeData['origin']['lng']
      );
      final destination = LatLng(
        routeData['destination']['lat'], 
        routeData['destination']['lng']
      );

      List<LatLng> waypoints = [];
      if (routeData['waypoints'] != null) {
        waypoints = routeData['waypoints'].map<LatLng>((p) => 
          LatLng(p['lat'], p['lng'])
        ).toList();
      }

      final routePoints = await _getRoutePoints(origin, destination, waypoints);
      _updateMapWithRoute(routePoints);
      
    } catch (e) {
      debugPrint('Error configurando ruta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la ruta: $e')),
      );
    } finally {
      setState(() => _loadingRoute = false);
    }
  }

  Map<String, dynamic> routeDataWithDefaults(Map<String, dynamic> routeData) {
    // Asegurar que todos los campos necesarios existan con valores por defecto
    return {
      'nombre': routeData['nombre'] ?? 'Ruta sin nombre',
      'origin': routeData['origin'] ?? {'lat': 25.367269, 'lng': -108.159213},
      'destination': routeData['destination'] ?? {'lat': 25.380139, 'lng': -108.128655},
      'waypoints': routeData['waypoints'] ?? [],
      'polyline': routeData['polyline'] ?? [],
      'priceList': routeData['priceList'] ?? [],
    };
  }

  void _updateMapWithRoute(List<LatLng> routePoints) {
    if (routePoints.isEmpty) return;

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('bus_route'),
          points: routePoints,
          color: Colors.blue,
          width: 5,
          geodesic: true,
        ),
      };

      // Centrar el mapa en la ruta
      _initialPosition = routePoints[routePoints.length ~/ 2];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFromLatLngList(routePoints), 100)
      );
    });
  }

  Future<List<LatLng>> _getRoutePoints(
    LatLng origin, LatLng destination, List<LatLng> waypoints) async {
    
    String waypointsParam = waypoints.isNotEmpty
      ? '&waypoints=optimize:true|${waypoints.map((p) => '${p.latitude},${p.longitude}').join('|')}'
      : '';

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
          return _decodePolyline(data['routes'][0]['overview_polyline']['points']);
        }
      }
      throw Exception('No se pudo obtener la ruta: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error al obtener ruta: $e');
      // Fallback: línea recta con waypoints
      return [origin, ...waypoints, destination];
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 12,
              ),
              polylines: _polylines,
              myLocationEnabled: _showUserLocation,
              myLocationButtonEnabled: false, // Usamos nuestro propio botón
              onMapCreated: (controller) {
                _mapController = controller;
              },
              zoomControlsEnabled: false,
            ),
            if (_loadingRoute)
              const Center(child: CircularProgressIndicator()),
            
            // Botón para mostrar/ocultar ubicación del usuario
            Positioned(
              right: 16,
              bottom: 120,
              child: FloatingActionButton(
                heroTag: 'location_button',
                mini: true,
                onPressed: _toggleUserLocation,
                child: Icon(
                  _showUserLocation ? Icons.location_on : Icons.location_off,
                  color: _showUserLocation ? const Color.fromARGB(255, 33, 243, 114) : const Color.fromARGB(255, 203, 201, 201),
                ),
              ),
            ),
            
            // Botón para centrar en la ruta
            Positioned(
              right: 16,
              bottom: 180,
              child: FloatingActionButton(
                heroTag: 'route_button',
                mini: true,
                onPressed: () {
                  if (_polylines.isNotEmpty) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        _boundsFromLatLngList(_polylines.first.points),
                        100,
                      ),
                    );
                  }
                },
                child: const Icon(Icons.alt_route, color: Color.fromARGB(255, 205, 210, 214)),
              ),
            ),
          ],
        ),
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}