import 'dart:async';
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

class RouteEditorScreen extends StatefulWidget {
  const RouteEditorScreen({super.key});

  @override
  State<RouteEditorScreen> createState() => _RouteEditorScreenState();
}

class _RouteEditorScreenState extends State<RouteEditorScreen> {
  // Variables de estado
  LatLng? _originPos;
  LatLng? _destPos;
  final List<LatLng> _waypointsPos = [];
  final List<LatLng> _polylinePoints = [];
  TimeOfDay? _horaSalida, _horaLlegada;
  GoogleMapController? _mapController;
  bool _pickingOrigin = false;
  bool _pickingDestination = false;
  bool _pickingWaypoint = false;
  bool _isSaving = false;
  final TextEditingController _nombreRutaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se necesitan permisos de ubicación')),
      );
    }
  }

  Future<List<LatLng>> _fetchRoutePoints({
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
      uri = uri.replace(
          query: '${uri.query}&waypoints=${Uri.encodeComponent(wp)}');
    }

    final response = await http.get(uri);
    final data = json.decode(response.body);

    if (data['status'] != 'OK') {
      throw Exception('Directions API error: ${data['status']}');
    }

    final encoded = data['routes'][0]['overview_polyline']['points'] as String;
    final pts = PolylinePoints().decodePolyline(encoded);
    return pts.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }

  Future<void> _selectPlaceAutocomplete(bool isOrigin) async {
    try {
      final p = await PlacesAutocomplete.show(
        context: context,
        apiKey: _kGoogleApiKey,
        mode: Mode.overlay,
        language: 'es',
      );

      if (p == null || p.placeId == null) return;

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

      if (_originPos != null && _destPos != null) {
        await _buildRoute();
      }
    } catch (e) {
      _showErrorSnackbar('Error al buscar lugar: $e');
    }
  }

  void _enableTapPick(String type) {
    setState(() {
      _pickingOrigin = type == 'origin';
      _pickingDestination = type == 'dest';
      _pickingWaypoint = type == 'waypoint';
    });

    String mensaje = 'Toque el mapa para seleccionar ';
    mensaje += _pickingOrigin
        ? 'Origen'
        : _pickingDestination
            ? 'Destino'
            : 'Waypoint';

    _showInfoSnackbar(mensaje);
  }

  Future<void> _buildRoute() async {
    if (_originPos == null || _destPos == null) return;

    try {
      final pts = await _fetchRoutePoints(
        origin: _originPos!,
        destination: _destPos!,
        waypoints: _waypointsPos,
      );

      setState(() {
        _polylinePoints
          ..clear()
          ..addAll(pts);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFromLatLngList(_polylinePoints),
          50.0,
        ),
      );
    } catch (e) {
      _showErrorSnackbar('No se pudo trazar la ruta: $e');
    }
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

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (t != null) {
      setState(() => isStart ? _horaSalida = t : _horaLlegada = t);
    }
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;

    // Verificar campos requeridos
    if (_originPos == null ||
        _destPos == null ||
        _horaSalida == null ||
        _horaLlegada == null) {
      _showErrorSnackbar('Complete todos los campos');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final doc = {
        'nombre': _nombreRutaController.text.trim(),
        'origin': {'lat': _originPos!.latitude, 'lng': _originPos!.longitude},
        'destination': {'lat': _destPos!.latitude, 'lng': _destPos!.longitude},
        'waypoints': _waypointsPos
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
        'horaSalida': _horaSalida!.format(context),
        'horaLlegada': _horaLlegada!.format(context),
        'createdAt': FieldValue.serverTimestamp(),
        'polylinePoints': _polylinePoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
      };

      // Esperar la operación de Firestore
      await FirebaseFirestore.instance.collection('busRoutes').add(doc);

      // Verificar si el widget sigue montado
      if (!mounted) return;

      // Navegar atrás después de guardar
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Error al guardar: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nombreRutaController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Ruta de Autobús'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(3.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Formulario desplazable
              SizedBox(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _nombreRutaController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la Ruta',
                            prefixIcon: Icon(Icons.drive_eta),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa un nombre';
                            }
                            return null;
                          },
                        ),
                      ),
                      _buildLocationRow(
                        'Origen',
                        _originPos,
                        () => _selectPlaceAutocomplete(true),
                        () => _enableTapPick('origin'),
                      ),
                      _buildLocationRow(
                        'Destino',
                        _destPos,
                        () => _selectPlaceAutocomplete(false),
                        () => _enableTapPick('dest'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.add_location_alt),
                                label: const Text('Agregar Waypoint'),
                                onPressed: () => _enableTapPick('waypoint'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            if (_waypointsPos.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _waypointsPos.clear());
                                  if (_originPos != null && _destPos != null) {
                                    _buildRoute();
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                      _buildTimePickerTile(
                        'Hora de salida',
                        _horaSalida,
                        () => _pickTime(true),
                      ),
                      _buildTimePickerTile(
                        'Hora de llegada',
                        _horaLlegada,
                        () => _pickTime(false),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.inversePrimary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator()
                              : const Text('Guardar Ruta'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Mapa interactivo
              _buildGoogleMap(),
            ])),
      ),
    );
  }

  Widget _buildGoogleMap() {
    return SizedBox(   
      height: 450,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _originPos ?? const LatLng(25.4, -108.12),
          zoom: 13,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          if (_originPos != null && _destPos != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngBounds(
                  _boundsFromLatLngList(_polylinePoints),
                  50.0,
                ),
              );
            });
          }
        },
        onTap: (pos) {
          if (_pickingOrigin) {
            setState(() => _originPos = pos);
            _pickingOrigin = false;
            if (_destPos != null) _buildRoute();
          } else if (_pickingDestination) {
            setState(() => _destPos = pos);
            _pickingDestination = false;
            if (_originPos != null) _buildRoute();
          } else if (_pickingWaypoint) {
            setState(() => _waypointsPos.add(pos));
            _pickingWaypoint = false;
            if (_originPos != null && _destPos != null) _buildRoute();
          }
        },
        markers: {
          if (_originPos != null)
            Marker(
              markerId: const MarkerId('origin'),
              position: _originPos!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
            ),
          if (_destPos != null)
            Marker(
              markerId: const MarkerId('dest'),
              position: _destPos!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ),
          for (var i = 0; i < _waypointsPos.length; i++)
            Marker(
              markerId: MarkerId('wp$i'),
              position: _waypointsPos[i],
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
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
    );
  }

  Widget _buildLocationRow(
    String label,
    LatLng? pos,
    VoidCallback onSearch,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearch,
            tooltip: 'Buscar $label',
          ),
          IconButton(
            icon: const Icon(Icons.touch_app),
            onPressed: onTap,
            tooltip: 'Seleccionar en mapa',
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerTile(
    String label,
    TimeOfDay? time,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: const Icon(Icons.schedule),
      title: Text(time == null
          ? '$label: No seleccionada'
          : '$label: ${time.format(context)}'),
      onTap: onTap,
    );
  }
}
