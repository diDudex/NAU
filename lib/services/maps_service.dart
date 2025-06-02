import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapsService {
  static const _apiKey = 'AIzaSyDBWSYFUP0wJK8McN03WVAzB_2yNH6JfQQ';

  Future<LatLng?> searchPlaceAutocomplete(BuildContext context) async {
    try {
      final p = await PlacesAutocomplete.show(
        context: context,
        apiKey: _apiKey,
        mode: Mode.overlay,
        language: 'es',
      );
      if (p == null) return null;
      
      final places = GoogleMapsPlaces(apiKey: _apiKey);
      final detail = await places.getDetailsByPlaceId(p.placeId!);
      final location = detail.result.geometry!.location;
      return LatLng(location.lat, location.lng);
    } catch (e) {
      throw Exception('Error al buscar lugar: $e');
    }
  }

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
      '&key=$_apiKey'
      '&mode=driving'
      '&alternatives=false',
    );

    if (waypoints != null && waypoints.isNotEmpty) {
      final wp = waypoints.map((p) => '${p.latitude},${p.longitude}').join('|');
      uri = uri.replace(query: '${uri.query}&waypoints=${Uri.encodeComponent(wp)}');
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
}