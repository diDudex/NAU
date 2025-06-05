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

// Modelo para los precios
class PriceItem {
  String placeName;
  double price;

  PriceItem({required this.placeName, required this.price});
}

Future<List<LatLng>> fetchRoutePoints({
  required LatLng origin,
  required LatLng destination,
  List<LatLng>? waypoints,
}) async {
  final originParam = '${origin.latitude},${origin.longitude}';
  final destParam = '${destination.latitude},${destination.longitude}';

  final queryParameters = {
    'origin': originParam,
    'destination': destParam,
    'key': _kGoogleApiKey,
    'mode': 'driving',
    'alternatives': 'false',
  };

  if (waypoints != null && waypoints.isNotEmpty) {
    final wp = waypoints.map((p) => '${p.latitude},${p.longitude}').join('|');
    queryParameters['waypoints'] = wp;
  }

  final uri = Uri.https(
    'maps.googleapis.com',
    '/maps/api/directions/json',
    queryParameters,
  );

  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw Exception('Error en la petición HTTP: ${response.statusCode}');
  }

  final data = json.decode(response.body);
  if (data['status'] != 'OK') {
    throw Exception('Directions API error: ${data['status']}');
  }

  final encoded = data['routes'][0]['overview_polyline']['points'] as String;
  final pts = PolylinePoints().decodePolyline(encoded);
  return pts.map((p) => LatLng(p.latitude, p.longitude)).toList();
}

class BusRoutesPage extends StatefulWidget {
  const BusRoutesPage({super.key});

  @override
  State<BusRoutesPage> createState() => _BusRoutesPageState();
}

class _BusRoutesPageState extends State<BusRoutesPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  LatLng? _originPos;
  LatLng? _destPos;
  final List<LatLng> _waypointsPos = [];
  final List<LatLng> _polylinePoints = [];
  final List<PriceItem> _priceList = [];
  GoogleMapController? _mapController;
  bool _pickingOrigin = false;
  bool _pickingDestination = false;
  bool _pickingWaypoint = false;
  final TextEditingController _nombreRutaController = TextEditingController();
  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Permission.location.request();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _nombreRutaController.dispose();
    _placeNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == 0) {
      // Cuando cambia a la pestaña "Lista de Rutas"
      _clearFormData();
    }
  }

  void _clearFormData() {
    setState(() {
      _originPos = null;
      _destPos = null;
      _waypointsPos.clear();
      _polylinePoints.clear();
      _priceList.clear();
      _nombreRutaController.clear();
      _placeNameController.clear();
      _priceController.clear();
      _pickingOrigin = false;
      _pickingDestination = false;
      _pickingWaypoint = false;
    });
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

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
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
      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(_originPos!, 13));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo trazar la ruta: $e')),
      );
    }
  }

  void _addPriceItem() {
    final placeName = _placeNameController.text.trim();
    final priceText = _priceController.text.trim();

    if (placeName.isEmpty || priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese nombre y precio')),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un precio válido')),
      );
      return;
    }

    setState(() {
      _priceList.add(PriceItem(placeName: placeName, price: price));
      _placeNameController.clear();
      _priceController.clear();
    });

    // Cerrar el teclado después de agregar
    FocusScope.of(context).unfocus();
  }

  void _removePriceItem(int index) {
    setState(() {
      _priceList.removeAt(index);
    });
  }

  Future<void> _saveRoute() async {
    if (_originPos == null ||
        _destPos == null ||
        _nombreRutaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }
    try {
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
        'priceList': _priceList
            .map((item) => {'placeName': item.placeName, 'price': item.price})
            .toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('Rutas').add(doc);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar la ruta: $e')),
      );
    }
  }

  Widget _buildPriceListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Lista de Precios:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        if (_priceList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No hay precios agregados'),
          ),
        ..._priceList.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return ListTile(
            title: Text(item.placeName),
            trailing: Text('\$${item.price.toStringAsFixed(2)}'),
            leading: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removePriceItem(index),
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _placeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Lugar',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: _addPriceItem,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _deleteRutas(String rutaId) async {
    try {
      await _firestore.collection('Rutas').doc(rutaId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta eliminada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar ruta: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Rutas'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Lista de Rutas'),
              Tab(icon: Icon(Icons.add), text: 'Agregar Rutas'),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Pestaña 1: Lista de rutas existentes
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('Rutas').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay rutas disponibles'));
                }

                final rutas = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: rutas.length,
                  itemBuilder: (context, index) {
                    final rutasDoc = rutas[index];
                    final data = rutasDoc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: const Icon(Icons.drive_eta),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['nombre']),
                            if (data['priceList'] != null &&
                                data['priceList'].isNotEmpty) ...[
                              Text(
                                  'Origen: ${data['priceList'][0]['placeName']}'),
                              Text(
                                  'Destino: ${data['priceList'].last['placeName']}'),
                            ] else
                              const Text('Sin origen/destino'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                // Cambia a la pestaña 2 (Agregar/Editar Ruta)
                                DefaultTabController.of(context).animateTo(1);

                                // Llena los campos con los datos de la ruta seleccionada
                                final nombre = data['nombre'] ?? '';
                                final origin = data['origin'];
                                final destination = data['destination'];
                                final waypoints =
                                    data['waypoints'] as List<dynamic>? ?? [];
                                final polyline =
                                    data['polyline'] as List<dynamic>? ?? [];
                                final priceList =
                                    data['priceList'] as List<dynamic>? ?? [];

                                setState(() {
                                  _nombreRutaController.text = nombre;
                                  _originPos = origin != null
                                      ? LatLng(origin['lat'] as double,
                                          origin['lng'] as double)
                                      : null;
                                  _destPos = destination != null
                                      ? LatLng(destination['lat'] as double,
                                          destination['lng'] as double)
                                      : null;
                                  _waypointsPos
                                    ..clear()
                                    ..addAll(waypoints.map((wp) => LatLng(
                                        wp['lat'] as double,
                                        wp['lng'] as double)));
                                  _polylinePoints
                                    ..clear()
                                    ..addAll(polyline.map((pt) => LatLng(
                                        pt['lat'] as double,
                                        pt['lng'] as double)));
                                  _priceList
                                    ..clear()
                                    ..addAll(priceList.map((item) => PriceItem(
                                          placeName: item['placeName'],
                                          price:
                                              (item['price'] as num).toDouble(),
                                        )));
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteRutas(rutasDoc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Pestaña 2: Agregar nuevas Rutas
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _nombreRutaController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Ruta',
                      prefixIcon: Icon(Icons.drive_eta),
                    ),
                  ),
                ),
                _buildLocationRow(
                    'Origen',
                    _originPos,
                    () => _selectPlaceAutocomplete(true),
                    () => _enableTapPick('origin')),
                _buildLocationRow(
                    'Destino',
                    _destPos,
                    () => _selectPlaceAutocomplete(false),
                    () => _enableTapPick('dest')),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.inversePrimary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                          icon: const Icon(Icons.add_location_alt),
                          label: const Text('Agregar Waypoint'),
                          onPressed: () => _enableTapPick('waypoint'),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPriceListSection(),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.inversePrimary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: _saveRoute,
                    child: const Text('Guardar Ruta'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 400,
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(
      String label, LatLng? pos, VoidCallback onSearch, VoidCallback onTap) {
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
}
