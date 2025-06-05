import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:nau/pages/seleccion.dart';
import 'package:nau/widgets/mapa.dart';
import 'package:nau/widgets/rutassugeridas.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchText = '';
  Map<String, dynamic>? _selectedBus;
  List<Map<String, dynamic>> _buses = [];
  Position? _currentPosition;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchBusesWithDetails();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    if (!status.isGranted) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      debugPrint("Error obteniendo ubicación: $e");
    }
  }

  Future<void> _fetchBusesWithDetails() async {
    try {
      // Obtener todos los buses
      final busesSnapshot = await _firestore.collection('Bus').get();

      // Para cada bus, obtener sus datos relacionados
      List<Map<String, dynamic>> busesWithDetails = [];

      for (var busDoc in busesSnapshot.docs) {
        final busData = busDoc.data();
        busData['id'] = busDoc.id;

        // Obtener datos de la ruta asociada
        if (busData['rutaid'] != null) {
          final rutaDoc = await _firestore
              .collection('Rutas')
              .doc(busData['rutaid'])
              .get();
          if (rutaDoc.exists) {
            busData['ruta'] = rutaDoc.data();
          }
        }

        // Obtener datos del horario asociado
        if (busData['horarios'] is List &&
            (busData['horarios'] as List).isNotEmpty) {
          final horarioId = (busData['horarios'] as List).first;
          final horarioDoc =
              await _firestore.collection('Horarios').doc(horarioId).get();
          if (horarioDoc.exists) {
            busData['horario'] = horarioDoc.data();
          }
        }

        busesWithDetails.add(busData);
      }

      setState(() {
        _buses = busesWithDetails;
      });
    } catch (e) {
      debugPrint("Error al obtener buses con detalles: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar buses: $e')),
      );
    }
  }

  Widget _buildSelectedBusCard() {
    if (_selectedBus == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Autobús seleccionado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedBus = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Image.asset(
                    'assets/bus_card.png',
                    height: 60,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedBus!['nombre'] ?? 'Sin nombre',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hora salida: ${_selectedBus!['horaSalida'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Hora llegada: ${_selectedBus!['horaLlegada'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.inversePrimary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(
                            double.infinity, 40), // Altura consistente
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MapaScreen(selectedBus: _selectedBus),
                          ),
                        );
                      },
                      child: const Text('Ver en el mapa'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(
                            double.infinity, 40), // Altura consistente
                      ),
                      onPressed: _selectedBus != null
                          ? () async {
                              // Navegar a selección de asientos y esperar resultado
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SeatSelectionScreen(
                                    busData: _selectedBus!,
                                    onTicketPurchased: () {
                                      // Callback para actualizar estado si es necesario
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        setState(() {});
                                      });
                                    },
                                  ),
                                ),
                              );

                              // Actualizar UI si se completó una compra
                              if (result == true) {
                                setState(() {
                                  _selectedBus =
                                      null; // Resetear selección si es necesario
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Compra realizada exitosamente')),
                                );
                              }
                            }
                          : null,
                      child: const Text(
                        'Comprar boleto',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Mapa de Rutas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // Barra de búsqueda
            Column(children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar autobús...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value.trim();
                    });
                  },
                ),
              ),
            ]),

            // Lista pequeña de resultados de búsqueda
            if (_searchText.isNotEmpty)
              Builder(
                builder: (context) {
                  final filteredBuses = _buses
                      .where((bus) {
                        final rutaNombre =
                            bus['ruta']?['nombre']?.toString().toLowerCase() ??
                                '';
                        final busNum =
                            bus['numBus']?.toString().toLowerCase() ?? '';
                        final search = _searchText.toLowerCase();

                        return rutaNombre.contains(search) ||
                            busNum.contains(search);
                      })
                      .where((bus) {
                        // Filtro por horarios disponibles
                        final horario = bus['horario'];
                        if (horario == null) return false;

                        final fechaStr = horario['fecha'];
                        final estado = bus['estado']?.toString().toLowerCase();

                        if (estado != 'activo') return false;

                        final fecha = fechaStr is Timestamp
                            ? fechaStr.toDate()
                            : DateTime.tryParse(fechaStr.toString());

                        if (fecha == null) return false;

                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final tomorrow = today.add(const Duration(days: 1));

                        // Mostrar buses de hoy o mañana
                        return (fecha.year == today.year &&
                                fecha.month == today.month &&
                                fecha.day == today.day) ||
                            (fecha.year == tomorrow.year &&
                                fecha.month == tomorrow.month &&
                                fecha.day == tomorrow.day);
                      })
                      .take(3)
                      .toList();

                  if (filteredBuses.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child:
                          Text('No se encontraron rutas para "$_searchText"'),
                    );
                  }

                  return SizedBox(
                    height: 170,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: filteredBuses.map((bus) {
                          final horario = bus['horario'];
                          final ruta = bus['ruta'];

                          DateTime? fechaViaje;
                          if (horario?['fecha'] is Timestamp) {
                            fechaViaje =
                                (horario!['fecha'] as Timestamp).toDate();
                          } else if (horario?['fecha'] != null) {
                            fechaViaje =
                                DateTime.tryParse(horario!['fecha'].toString());
                          }

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Image.asset(
                              'assets/bus_card.png',
                              height: 32,
                              width: 32,
                            ),
                            title: Text(
                              ruta?['nombre'] ?? 'Autobús ${bus['numBus']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (horario != null) ...[
                                  Text(
                                      'Salida: ${horario['horainicio'] ?? 'N/A'}'),
                                  Text(
                                      'Llegada: ${horario['horaFin'] ?? 'N/A'}'),
                                ],
                                if (fechaViaje != null)
                                  Text(
                                      'Fecha: ${DateFormat('dd/MM/yyyy').format(fechaViaje)}'),
                                if (fechaViaje != null &&
                                    fechaViaje.day == DateTime.now().day + 1)
                                  const Text('(Mañana)',
                                      style: TextStyle(color: Colors.green)),
                                Text('Estado: ${bus['estado'] ?? 'N/A'}'),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _selectedBus = bus;
                                _searchText = '';
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),

            // Mapa de rutas
            SizedBox(
              height: 380,
              child: MapaScreen(
                selectedBus: _selectedBus,
                currentPosition: _currentPosition,
              ),
            ),

            // Parte inferior (rutas sugeridas)
            SizedBox(
              height: 400,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mostrar autobús seleccionado
                      _buildSelectedBusCard(),
                      const SizedBox(height: 16),
                      const Text(
                        'Rutas sugeridas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RutasSugeridas(
                        onBusSelected: (bus) {
                          setState(() {
                            _selectedBus = bus;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
