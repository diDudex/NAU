import 'package:flutter/material.dart';
import 'package:nau/pages/mapa/MapaUbicacionWidget.dart';
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text('Inicio')),
      body: const Column(
        children: [
          MapaUbicacionWidget(), // Widget que muestra el mapa con la ubicación actual
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
