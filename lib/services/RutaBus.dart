/*import 'package:google_maps_flutter/google_maps_flutter.dart';

class RutaBus {
  final String nombre;
  final LatLng origen;
  final LatLng destino;
  final List<LatLng> waypoints;
  final List<LatLng> polyline;
  final String horaSalida;
  final String horaLlegada;

  RutaBus({
    required this.nombre,
    required this.origen,
    required this.destino,
    required this.waypoints,
    required this.polyline,
    required this.horaSalida,
    required this.horaLlegada,
  });

  factory RutaBus.fromMap(Map<String, dynamic> data) {
    LatLng parseLatLng(Map<String, dynamic> point) =>
        LatLng(point['lat'], point['lng']);

    List<LatLng> parseList(List<dynamic> list) =>
        list.map((e) => parseLatLng(e as Map<String, dynamic>)).toList();

    return RutaBus(
      nombre: data['nombre'] ?? '',
      origen: parseLatLng(data['origin']),
      destino: parseLatLng(data['destination']),
      waypoints: parseList(data['waypoints'] ?? []),
      polyline: parseList(data['polyline'] ?? []),
      horaSalida: data['horaSalida'] ?? '',
      horaLlegada: data['horaLlegada'] ?? '',
    );
  }
}
*/