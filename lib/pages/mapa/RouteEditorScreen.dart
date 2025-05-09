// lib/screens/route_editor_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

const _kGoogleApiKey = 'AIzaSyDBWSYFUP0wJK8McN03WVAzB_2yNH6JfQQ';
final _placesService = GoogleMapsPlaces(apiKey: _kGoogleApiKey);

Future<List<LatLng>> fetchRoutePoints({
  required LatLng origin,
  required LatLng destination,
  List<LatLng>? waypoints,
}) async {
  final originParam = '${origin.latitude},${origin.longitude}';
  final destParam = '${destination.latitude},${destination.longitude}';
  var uri = Uri.parse(
    'https://maps.googleapis.com/maps/api/directions/json'
    '?origin=$originParam'
    '&destination=$destParam'
    '&key=$_kGoogleApiKey'
    '&mode=driving'
    '&alternatives=false',
  );

  if (waypoints != null && waypoints.isNotEmpty) {
    final wp = waypoints.map((p) => '${p.latitude},${p.longitude}').join('|');
    uri = uri.replace(query: '${uri.query}&waypoints=${Uri.encodeComponent(wp)}');
  }

  final response = await http.get(uri);
  final data = json.decode(response.body);
  if (data['status'] != 'OK') throw Exception('Directions API error: ${data['status']}');

  final encoded = data['routes'][0]['overview_polyline']['points'] as String;
  final pts = PolylinePoints().decodePolyline(encoded);
  return pts.map((p) => LatLng(p.latitude, p.longitude)).toList();
}

class RouteEditorScreen extends StatefulWidget {
  const RouteEditorScreen({super.key});

  @override
  State<RouteEditorScreen> createState() => _RouteEditorScreenState();
}

class _RouteEditorScreenState extends State<RouteEditorScreen> {
  LatLng? _originPos;
  LatLng? _destPos;
  final List<LatLng> _waypointsPos = [];
  final List<LatLng> _polylinePoints = [];
  TimeOfDay? _horaSalida, _horaLlegada;
  GoogleMapController? _mapController;
  bool _pickingOrigin = false;
  bool _pickingDestination = false;
  bool _pickingWaypoint = false;
  final TextEditingController _nombreRutaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Permission.location.request();
  }

  Future<void> _selectPlaceAutocomplete(bool isOrigin) async {
    try {
      final p = await PlacesAutocomplete.show(
        context: context,
        apiKey: _kGoogleApiKey,
        mode: Mode.overlay,
        language: 'es',
      );
      if (p == null) return;
      final detail = await _placesService.getDetailsByPlaceId(p.placeId!);
      final lat = detail.result.geometry!.location.lat;
      final lng = detail.result.geometry!.location.lng;
      setState(() {
        if (isOrigin) {
          _originPos = LatLng(lat, lng);
        } else {
          _destPos = LatLng(lat, lng);
        }
      });
      if (_originPos != null && _destPos != null) await _buildRoute();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar lugar: $e')),
      );
    }
  }

  void _enableTapPick(String type) {
    setState(() {
      _pickingOrigin = type == 'origin';
      _pickingDestination = type == 'dest';
      _pickingWaypoint = type == 'waypoint';
    });

    String mensaje = 'Toque el mapa para seleccionar ';
    if (_pickingOrigin) mensaje += 'Origen';
    if (_pickingDestination) mensaje += 'Destino';
    if (_pickingWaypoint) mensaje += 'Waypoint';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _buildRoute() async {
    if (_originPos == null || _destPos == null) return;
    try {
      final pts = await fetchRoutePoints(
        origin: _originPos!,
        destination: _destPos!,
        waypoints: _waypointsPos,
      );
      setState(() {
        _polylinePoints
          ..clear()
          ..addAll(pts);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_originPos!, 13));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo trazar la ruta: $e')),
      );
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => isStart ? _horaSalida = t : _horaLlegada = t);
  }

  Future<void> _saveRoute() async {
    if (_originPos == null ||
        _destPos == null ||
        _horaSalida == null ||
        _horaLlegada == null ||
        _nombreRutaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }
    final doc = {
      'nombre': _nombreRutaController.text.trim(),
      'origin': {'lat': _originPos!.latitude, 'lng': _originPos!.longitude},
      'destination': {'lat': _destPos!.latitude, 'lng': _destPos!.longitude},
      'waypoints': _waypointsPos
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'polyline': _polylinePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'horaSalida': _horaSalida!.format(context),
      'horaLlegada': _horaLlegada!.format(context),
      'createdAt': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance.collection('busRoutes').add(doc);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Ruta de Autobús')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _nombreRutaController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Ruta',
                prefixIcon: Icon(Icons.drive_eta),
              ),
            ),
          ),
          _buildLocationRow('Origen', _originPos, () => _selectPlaceAutocomplete(true), () => _enableTapPick('origin')),
          _buildLocationRow('Destino', _destPos, () => _selectPlaceAutocomplete(false), () => _enableTapPick('dest')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text('Waypoint (buscar)'),
                    onPressed: () => _enableTapPick('waypoint'),
                  ),
                ),
              ],
            ),
          ),
          _buildTimePickerTile('Hora de salida', _horaSalida, () => _pickTime(true)),
          _buildTimePickerTile('Hora de llegada', _horaLlegada, () => _pickTime(false)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: _saveRoute,
              child: const Text('Guardar Ruta en Firestore'),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _originPos ?? const LatLng(25.4, -108.12),
                zoom: 13,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onTap: (pos) {
                if (_pickingOrigin) {
                  setState(() => _originPos = pos);
                  _buildRoute();
                } else if (_pickingDestination) {
                  setState(() => _destPos = pos);
                  _buildRoute();
                } else if (_pickingWaypoint) {
                  setState(() => _waypointsPos.add(pos));
                  _buildRoute();
                }
              },
              markers: {
                if (_originPos != null)
                  Marker(
                    markerId: const MarkerId('origin'),
                    position: _originPos!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  ),
                if (_destPos != null)
                  Marker(
                    markerId: const MarkerId('dest'),
                    position: _destPos!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ),
                for (var i = 0; i < _waypointsPos.length; i++)
                  Marker(
                    markerId: MarkerId('wp$i'),
                    position: _waypointsPos[i],
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  ),
              },
              polylines: {
                if (_polylinePoints.isNotEmpty)
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: _polylinePoints,
                    color: Colors.blue,
                    width: 5,
                  ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String label, LatLng? pos, VoidCallback onSearch, VoidCallback onTap) {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            leading: const Icon(Icons.place),
            title: Text(
              pos == null
                  ? '$label: no definido'
                  : '$label: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.search), onPressed: onSearch),
        IconButton(icon: const Icon(Icons.touch_app), onPressed: onTap),
      ],
    );
  }

  Widget _buildTimePickerTile(String label, TimeOfDay? time, VoidCallback onTap) {
    return ListTile(
      leading: const Icon(Icons.schedule),
      title: Text(time == null ? label : '$label: ${time.format(context)}'),
      onTap: onTap,
    );
  }
}
