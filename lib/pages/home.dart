import 'package:flutter/material.dart';
import 'package:nau/pages/mapa/mapade_rutas.dart'; // Asegúrate de importar el widget

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final bool _mapVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: Column(
        children: [
          if (_mapVisible)
            const SizedBox(
              height: 300, // Altura del mapa desplegado
              child: MapadeRutas(),
            ),
          const SizedBox(height: 10),
          // Aquí puedes agregar el resto del contenido de tu pantalla de inicio
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Bienvenido a la app de transporte',
              style: TextStyle(fontSize: 18),
            ),
          ),
          // Más contenido aquí...
        ],
      ),
    );
  }
}
