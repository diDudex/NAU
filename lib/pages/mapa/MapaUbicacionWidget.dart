import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapaUbicacionWidget extends StatefulWidget {
  const MapaUbicacionWidget({super.key});

  @override
  State<MapaUbicacionWidget> createState() => _MapaUbicacionWidgetState();
}

class _MapaUbicacionWidgetState extends State<MapaUbicacionWidget> {
  GoogleMapController? _mapController;
  LatLng? _ubicacionUsuario;
  Marker? _marcadorUsuario;
  bool _mostrarMapa = true;

  @override
  void initState() {
    super.initState();
    _cargarUltimaUbicacion().then((_) => _obtenerUbicacionActual());
  }

  Future<void> _cargarUltimaUbicacion() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('ultima_lat'); // Cargar la última latitud guardada
    final lng = prefs.getDouble('ultima_lng'); // Cargar la última longitud guardada

    if (lat != null && lng != null) {
      setState(() {
        _ubicacionUsuario = LatLng(lat, lng);
        _marcadorUsuario = Marker(
          markerId: MarkerId("ubicacion_guardada"),
          position: _ubicacionUsuario!,
          infoWindow: InfoWindow(title: "Última ubicación guardada"),
        );
      });
    }
  }

  Future<void> _guardarUbicacion(LatLng ubicacion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ultima_lat', ubicacion.latitude); // Guardar la latitud
    await prefs.setDouble('ultima_lng', ubicacion.longitude);   // Guardar la longitud
    // aqui se puede agregar lógica adicional para guardar la ubicación en una base de datos o enviarla a un servidor
  }

  Future<void> _obtenerUbicacionActual() async {
    final permiso = await Permission.location.request();
    if (!permiso.isGranted) return;

    final posicion = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final nuevaUbicacion = LatLng(posicion.latitude, posicion.longitude);

    setState(() {
      _ubicacionUsuario = nuevaUbicacion;
      _marcadorUsuario = Marker(
        markerId: MarkerId("ubicacion_usuario"),
        position: nuevaUbicacion,
        infoWindow: InfoWindow(title: "Estás aquí"),
      );
    });

    _guardarUbicacion(nuevaUbicacion);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(nuevaUbicacion, 16),
    );
  }

  void _toggleMapa() {
    setState(() {
      _mostrarMapa = !_mostrarMapa;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botón para plegar/desplegar
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton.icon(
              onPressed: _toggleMapa,
              icon: Icon(_mostrarMapa ? Icons.expand_less : Icons.expand_more),
              label: Text(_mostrarMapa ? "Ocultar mapa" : "Mostrar mapa"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ),
        // Contenedor del mapa animado
        AnimatedContainer(
          duration: Duration(milliseconds: 400),
          height: _mostrarMapa ? 250 : 0,
          child: _ubicacionUsuario == null
              ? Center(child: CircularProgressIndicator())
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: _ubicacionUsuario!,
                      zoom: 16,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _marcadorUsuario != null ? {_marcadorUsuario!} : {},
                  ),
                ),
        ),
      ],
    );
  }
}
