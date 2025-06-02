import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusRoute {
  final String? id;
  final String name;
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> waypoints;
  final List<LatLng> polyline;
  final TimeOfDay departureTime;
  final TimeOfDay arrivalTime;
  final DateTime createdAt;

  BusRoute({
    this.id,
    required this.name,
    required this.origin,
    required this.destination,
    this.waypoints = const [],
    required this.polyline,
    required this.departureTime,
    required this.arrivalTime,
    required this.createdAt,
  });

  BusRoute copyWith({
    String? id,
    String? name,
    LatLng? origin,
    LatLng? destination,
    List<LatLng>? waypoints,
    List<LatLng>? polyline,
    TimeOfDay? departureTime,
    TimeOfDay? arrivalTime,
    DateTime? createdAt,
  }) {
    return BusRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      waypoints: waypoints ?? this.waypoints,
      polyline: polyline ?? this.polyline,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}