import 'package:flutter/material.dart';
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
  String _selectedFilter = 'Todos';
  String _selectedSort = 'Cercanía';
  Map<String, dynamic>? _selectedBus;

  @override
  void initState() {
    super.initState();
    Permission.location.request();
    _fetchBuses();
  }

  List<Map<String, dynamic>> _buses = [];

  Future<void> _fetchBuses() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('busRoutes').get();
    setState(() {
      _buses = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
    });
  }

  Widget _buildSelectedBusCard() {
    if (_selectedBus == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 12),
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
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
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

  // Función auxiliar mejorada para parsear horas
  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return const TimeOfDay(hour: 0, minute: 0);

      final timePart = parts[0].split(':');
      if (timePart.length < 2) return const TimeOfDay(hour: 0, minute: 0);

      int hour = int.parse(timePart[0]);
      final minute = int.parse(timePart[1]);
      final period = parts[1].toUpperCase();

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint("Error parsing time: $e");
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  void _applySorting() {
    setState(() {
      switch (_selectedSort) {
        case 'Cercanía':
          // Implementa lógica de cercanía basada en ubicación
          _buses.sort((a, b) {
            // Aquí deberías comparar distancias
            return 0;
          });
          break;
        case 'Tiempo':
          _buses.sort((a, b) {
            final aTime = _parseTime(a['horaSalida'] ?? '12:00 AM');
            final bTime = _parseTime(b['horaSalida'] ?? '12:00 AM');
            return aTime.hour.compareTo(bTime.hour);
          });
          break;
        case 'Nombre':
          _buses.sort((a, b) => (a['nombre'] ?? '')
              .toString()
              .compareTo((b['nombre'] ?? '').toString()));
          break;
        case 'Precio':
          _buses.sort((a, b) => (a['precio'] ?? 0).compareTo(b['precio'] ?? 0));
          break;
      }
    });
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Barra de búsqueda
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar autobús',
                    prefixIcon: const Icon(Icons.search),
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
              // Lista pequeña de resultados de búsqueda
              if (_searchText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buses
                        .where((bus) {
                          // Filtro por nombre
                          final nombre =
                              (bus['nombre'] ?? '').toString().toLowerCase();
                          final search = _searchText.toLowerCase();
                          return nombre.split('-').any(
                                  (part) => part.trim().startsWith(search)) ||
                              nombre.contains(search);
                        })
                        .where((bus) {
                          final horaSalidaStr = bus['horaSalida'];
                          if (horaSalidaStr == null) return false;

                          final busDate = bus['createdAt'] != null
                              ? (bus['createdAt'] is Timestamp
                                  ? (bus['createdAt'] as Timestamp).toDate()
                                  : DateTime.tryParse(
                                      bus['createdAt'].toString()))
                              : null;

                          if (busDate == null) return false;

                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final tomorrow = today.add(const Duration(days: 1));

                          // Mostrar todos los autobuses de mañana
                          if (busDate.year == tomorrow.year &&
                              busDate.month == tomorrow.month &&
                              busDate.day == tomorrow.day) {
                            return true;
                          }

                          // Para autobuses de hoy, mostrar solo los que salen después de ahora
                          if (busDate.year == now.year &&
                              busDate.month == now.month &&
                              busDate.day == now.day) {
                            final salida = _parseTime(horaSalidaStr);
                            final salidaDateTime = DateTime(
                                busDate.year,
                                busDate.month,
                                busDate.day,
                                salida.hour,
                                salida.minute);
                            return salidaDateTime.isAfter(now);
                          }

                          return false;
                        })
                        .take(3)
                        .map((bus) {
                          final busDate =
                              (bus['createdAt'] as Timestamp).toDate();
                          final fechaStr =
                              DateFormat('dd/MM/yyyy').format(busDate);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Image.asset(
                              'assets/bus_card.png',
                              height: 32,
                              width: 32,
                            ),
                            title: Text(bus['nombre'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Hora salida: ${bus['horaSalida'] ?? 'N/A'}'),
                                Text('Fecha: $fechaStr'),
                                if (busDate.day == DateTime.now().day + 1)
                                  const Text('(Mañana)',
                                      style: TextStyle(color: Colors.green)),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _selectedBus = bus;
                                _searchText = '';
                              });
                            },
                          );
                        })
                        .toList(),
                  ),
                ),
              // Filtros y orden
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // Filtro por ruta
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedFilter,
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor:
                                  Theme.of(context).colorScheme.background,
                            ),
                            icon: const Icon(Icons.filter_alt_outlined),
                            borderRadius: BorderRadius.circular(12),
                            items: [
                              'Todos',
                              ..._buses
                                  .map((bus) => bus['nombre'] as String)
                                  .toSet()
                                  .toList()
                            ].map((f) {
                              return DropdownMenuItem(
                                value: f,
                                child: Text(
                                  f,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFilter = value!;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Ordenamiento
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSort,
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor:
                                  Theme.of(context).colorScheme.background,
                            ),
                            icon: const Icon(Icons.sort),
                            borderRadius: BorderRadius.circular(12),
                            items: [
                              DropdownMenuItem(
                                value: 'Cercanía',
                                child: Row(
                                  children: [
                                    const Icon(Icons.near_me, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('Cercanía'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Tiempo',
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('Hora salida'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Nombre',
                                child: Row(
                                  children: [
                                    const Icon(Icons.sort_by_alpha, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('Nombre'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Precio',
                                child: Row(
                                  children: [
                                    const Icon(Icons.attach_money, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('Precio'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedSort = value!;
                                _applySorting();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Mapa de rutas
              const SizedBox(
                height: 400,
                child: MapaScreen(),
              ),

              // Mostrar autobús seleccionado
              _buildSelectedBusCard(),

              const SizedBox(height: 16),
              // Rutas sugeridas
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
            ],
          ),
        ),
      ),
    );
  }
}
