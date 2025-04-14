import 'package:flutter/material.dart';
import 'package:nau/widgets/rutassugeridas.dart';

class HomeScreen extends StatelessWidget {
  final List<Map<String, String>> demoRoutes = [
    {'origen': 'Centro', 'destino': 'Terminal Norte', 'tiempo': '25 min'},
    {'origen': 'Universidad', 'destino': 'Centro', 'tiempo': '15 min'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inicio')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, Usuario', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Rutas sugeridas', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            RutasSugeridas(routes: demoRoutes),
          ],
        ),
      ),
    );
  }
}
