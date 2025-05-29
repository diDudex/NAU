/*import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class RutasConAnimacion extends StatefulWidget {
  const RutasConAnimacion({super.key});

  @override
  _RutasConAnimacionState createState() => _RutasConAnimacionState();
}

class _RutasConAnimacionState extends State<RutasConAnimacion> {
  GoogleMapController? _mapController;
  final Map<PolylineId, Polyline> _polylines = {};
  List<LatLng> _rutaActual = [];
  LatLng? _posicionAutobus;
  BitmapDescriptor? _busIcon;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargarIconoAutobus();
    _cargarRutasDesdeFirestore();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarIconoAutobus() async {
    _busIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/bus_icon.png', // Asegúrate de agregar este ícono a tu proyecto
    );
  }

  Future<void> _cargarRutasDesdeFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('rutas').get();
    if (snapshot.docs.isEmpty) return;

    final doc = snapshot.docs.first; // Por simplicidad, tomamos una ruta
    final data = doc.data();
    final puntos = (data['puntos'] as List)
        .map((p) => LatLng(p['lat'], p['lng']))
        .toList();

    final salida = _parsearHora(data['horaSalida']);
    final llegada = _parsearHora(data['horaLlegada']);
    final duracion = llegada.difference(salida).inSeconds;

    setState(() {
      _rutaActual = puntos;
      _polylines[PolylineId(doc.id)] = Polyline(
        polylineId: PolylineId(doc.id),
        color: Colors.blue,
        width: 5,
        points: puntos,
      );
    });

    _iniciarAnimacion(puntos, duracion);
  }

  DateTime _parsearHora(String hora) {
    final now = DateTime.now();
    final format = DateFormat("HH:mm");
    final parsedTime = format.parse(hora);
    return DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
  }

  void _iniciarAnimacion(List<LatLng> puntos, int duracionSegundos) {
    final totalPuntos = puntos.length;
    int currentIndex = 0;

    _timer = Timer.periodic(Duration(seconds: duracionSegundos ~/ totalPuntos), (timer) {
      if (currentIndex >= puntos.length) {
        timer.cancel();
        return;
      }

      setState(() {
        _posicionAutobus = puntos[currentIndex];
      });

      currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rutas con Animación")),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(25.0, -107.0),
          zoom: 13,
        ),
        onMapCreated: (controller) => _mapController = controller,
        polylines: Set<Polyline>.of(_polylines.values),
        markers: _posicionAutobus != null && _busIcon != null
            ? {
                Marker(
                  markerId: const MarkerId("bus"),
                  position: _posicionAutobus!,
                  icon: _busIcon!,
                ),
              }
            : {},
      ),
    );
  }
}
*/