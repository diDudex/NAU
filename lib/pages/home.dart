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

  // ignore: unused_field
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchBuses();
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

  Future<void> _fetchBuses() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('Bus').get();

      setState(() {
        _buses = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint("Error al obtener buses: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar rutas: $e')),
      );
    }
  }

  // ignore: unused_element
  double _calculateDistance(Position position, double lat, double lng) {
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      lat,
      lng,
    );
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

  // Para manejar posibles formatos diferentes:
  TimeOfDay _parseTime(dynamic timeValue) {
    try {
      String timeStr = timeValue?.toString() ?? '12:00 AM';

      // Intenta manejar diferentes formatos
      if (!timeStr.contains(' ')) {
        // Si no tiene AM/PM, asumir formato 24h
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          int hour = int.tryParse(parts[0]) ?? 0;
          int minute = int.tryParse(parts[1]) ?? 0;
          return TimeOfDay(hour: hour, minute: minute);
        }
      }

      // Procesar formato AM/PM estándar
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
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
                      _searchText = value
                          .trim(); // Usamos trim() para eliminar espacios en blanco
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
                        final rutasId =
                            (bus['rutasid'] ?? '').toString().toLowerCase();
                        final search = _searchText.toLowerCase();
                        return rutasId.split('-').any(
                                (part) => part.trim().startsWith(search)) ||
                            rutasId.contains(search);
                      })
                      .where((bus) {
                        // Obtener la hora de llegada desde horarios['horaLlegada']
                        dynamic horariosRaw = bus['horarios'];
                        String? horaLlegadaStr;
                        if (horariosRaw is Map<String, dynamic>) {
                          horaLlegadaStr = horariosRaw['horaLlegada'];
                        } else if (horariosRaw is List &&
                            horariosRaw.isNotEmpty) {
                          // Si es una lista, intenta tomar el primer elemento si es un mapa
                          final first = horariosRaw.first;
                          if (first is Map<String, dynamic>) {
                            horaLlegadaStr = first['horaLlegada'];
                          }
                        }
                        if (horaLlegadaStr == null) return false;

                        // Usar 'fecha' en vez de 'createdAt'
                        final fecha = bus['fecha'] != null
                            ? (bus['fecha'] is Timestamp
                                ? (bus['fecha'] as Timestamp).toDate()
                                : DateTime.tryParse(bus['fecha'].toString()))
                            : null;

                        if (fecha == null) return false;

                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final tomorrow = today.add(const Duration(days: 1));

                        if (fecha.year == tomorrow.year &&
                            fecha.month == tomorrow.month &&
                            fecha.day == tomorrow.day) {
                          return true;
                        }

                        if (fecha.year == now.year &&
                            fecha.month == now.month &&
                            fecha.day == now.day) {
                          final llegada = _parseTime(horaLlegadaStr);
                          final llegadaDateTime = DateTime(
                              fecha.year,
                              fecha.month,
                              fecha.day,
                              llegada.hour,
                              llegada.minute);
                          return llegadaDateTime.isAfter(now);
                        }

                        return false;
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
                          // Obtener la fecha desde horarios['fecha'] si existe, si no, usar bus['fecha']
                          DateTime? busDate;
                          dynamic horariosRaw = bus['horarios'];
                          if (horariosRaw is Map<String, dynamic> &&
                              horariosRaw['fecha'] != null) {
                            if (horariosRaw['fecha'] is Timestamp) {
                              busDate =
                                  (horariosRaw['fecha'] as Timestamp).toDate();
                            } else if (horariosRaw['fecha'] is String) {
                              busDate = DateTime.tryParse(horariosRaw['fecha']);
                            }
                          } else if (horariosRaw is List &&
                              horariosRaw.isNotEmpty) {
                            final first = horariosRaw.first;
                            if (first is Map<String, dynamic> &&
                                first['fecha'] != null) {
                              if (first['fecha'] is Timestamp) {
                                busDate =
                                    (first['fecha'] as Timestamp).toDate();
                              } else if (first['fecha'] is String) {
                                busDate = DateTime.tryParse(first['fecha']);
                              }
                            }
                          }

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Image.asset(
                              'assets/bus_card.png',
                              height: 32,
                              width: 32,
                            ),
                            title: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('Rutas')
                                  .doc(bus['rutasid'])
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text('Cargando ruta...');
                                }
                                if (!snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return Text(bus['nombre'] ?? '');
                                }
                                final rutaData = snapshot.data!.data()
                                    as Map<String, dynamic>?;
                                final rutaNombre =
                                    rutaData?['nombre'] ?? bus['nombre'] ?? '';
                                return Text(rutaNombre);
                              },
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Builder(
                                  builder: (context) {
                                    final now = DateTime.now();
                                    final salida = _parseTime(
                                        bus['horaSalida'] ?? '12:00 AM');
                                    final llegada = _parseTime(
                                        bus['horaLlegada'] ?? '12:00 AM');
                                    final salidaDateTime = busDate != null
                                        ? DateTime(
                                            busDate.year,
                                            busDate.month,
                                            busDate.day,
                                            salida.hour,
                                            salida.minute,
                                          )
                                        : DateTime.now();
                                    final llegadaDateTime = busDate != null
                                        ? DateTime(
                                            busDate.year,
                                            busDate.month,
                                            busDate.day,
                                            llegada.hour,
                                            llegada.minute,
                                          )
                                        : DateTime.now();

                                    String formatDuration(int totalMinutes) {
                                      final hours = totalMinutes ~/ 60;
                                      final minutes = totalMinutes % 60;
                                      if (hours > 0 && minutes > 0) {
                                        return '$hours hora${hours > 1 ? 's' : ''} $minutes minutos';
                                      } else if (hours > 0) {
                                        return '$hours hora${hours > 1 ? 's' : ''}';
                                      } else {
                                        return '$minutes minutos';
                                      }
                                    }

                                    if (now.isBefore(salidaDateTime)) {
                                      final minutosSalida = salidaDateTime
                                          .difference(now)
                                          .inMinutes;
                                      return Text(
                                          'Sale en: ${formatDuration(minutosSalida)}');
                                    } else if (now.isAfter(salidaDateTime) &&
                                        now.isBefore(llegadaDateTime)) {
                                      final minutosLlegada = llegadaDateTime
                                          .difference(now)
                                          .inMinutes;
                                      final minutosSalida = now
                                          .difference(salidaDateTime)
                                          .inMinutes;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Salió hace: ${formatDuration(minutosSalida)}',
                                            style: const TextStyle(
                                                color: Colors.red),
                                          ),
                                          Text(
                                            'Llega en: ${formatDuration(minutosLlegada)}',
                                            style: const TextStyle(
                                                color: Colors.orange),
                                          ),
                                        ],
                                      );
                                    } else if (now.isAfter(llegadaDateTime)) {
                                      return Text(
                                        'Llegó a las: ${bus['horaLlegada'] ?? 'N/A'}',
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      );
                                    } else {
                                      return Text(
                                          'Hora salida: ${bus['horaSalida'] ?? 'N/A'}');
                                    }
                                  },
                                ),
                                Text(
                                    'Fecha: ${busDate != null ? DateFormat('dd/MM/yyyy').format(busDate) : 'N/A'}'),
                                if (busDate != null &&
                                    busDate.day == DateTime.now().day + 1)
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
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),

            // Mapa de rutas
            const SizedBox(
              height: 380,
              child: MapaScreen(),
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
