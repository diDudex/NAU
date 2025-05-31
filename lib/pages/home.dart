import 'package:flutter/material.dart';
import 'package:nau/pages/mapa/mapade_rutas.dart';
import 'package:nau/widgets/mapa.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _mapVisible = true;
  bool _isLoadingLocation = true;
  String _searchText = '';
  String _selectedFilter = 'Todos';
  String _selectedSort = 'Cercanía';

  @override
  void initState() {
    super.initState();
    Permission.location.request();
  }

  // Ejemplo de lista de camiones
  final List<Map<String, String>> _buses = [
    {
      'nombre': 'Camion numero 3',
      'distancia': '15 minutos de distancia',
      'imagen': 'assets/bus_card.png', // Asegúrate de tener esta imagen
    },
    // Puedes agregar más camiones aquí
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Rutas'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Angostura',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {},
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
          ),
          // Filtros y orden
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Filtro
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: ['Todos', 'Ruta 1', 'Ruta 2']
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
                const SizedBox(width: 8),
                // Orden
                DropdownButton<String>(
                  value: _selectedSort,
                  items: ['Cercanía', 'Tiempo', 'Nombre']
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSort = value!;
                    });
                  },
                ),
                const Spacer(),
                const Text('99 results'),
              ],
            ),
          ),
          // Espacio entre la barra de búsqueda y el mapa
          const SizedBox(height: 20),
          // Mapa de rutas
          const SizedBox(
            height: 400,
            child: MapaScreen(),
          ),
          const SizedBox(height: 20),
          // Lista de camiones (ejemplo)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _buses.length,
            itemBuilder: (context, index) {
              final bus = _buses[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Image.asset(
                        bus['imagen']!,
                        height: 80,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bus['nombre']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        bus['distancia']!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .inversePrimary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                            onPressed: () {
                            Navigator.pushNamed(context, '/seleccion');
                          },
                          child: const Text('Seleccionar ubicación'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
