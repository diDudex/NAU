import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  _MapaScreenState createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(19.4326, -99.1332); // CDMX por default
  Marker? _userMarker;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
  }

  Future<void> _obtenerUbicacionActual() async {
    var permiso = await Permission.location.request();

    if (permiso.isGranted) {
      Position posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _initialPosition = LatLng(posicion.latitude, posicion.longitude);
        _userMarker = Marker(
          markerId: const MarkerId("ubicacion_usuario"),
          position: _initialPosition,
          infoWindow: const InfoWindow(title: "Estás aquí"),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _initialPosition,
            zoom: 17,
          ),
        ),
      );
    } else {
      print("Permiso denegado");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa del usuario")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 14,
        ),
        markers: _userMarker != null ? {_userMarker!} : {},
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}
