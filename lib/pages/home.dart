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
  String? _selectedFilter;
  String? _selectedSort;
  Map<String, dynamic>? _selectedBus;

  List<Map<String, dynamic>> _buses = [];
  List<Map<String, dynamic>> _filteredBuses = [];
  bool _isLoading = true;

  Position? _currentPosition;

  bool _filtersApplied = false;

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
      _applyFilters();
    } catch (e) {
      debugPrint("Error obteniendo ubicación: $e");
    }
  }

  Future<void> _fetchBuses() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('busRoutes').get();

      setState(() {
        _buses = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error al obtener buses: $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar rutas: $e')),
      );
    }
  }

  double _calculateDistance(Position position, double lat, double lng) {
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      lat,
      lng,
    );
  }

  void _applyFilters() {
    setState(() {
      _filtersApplied = true; // Marcamos que los filtros han sido aplicados
    });

    List<Map<String, dynamic>> filtered = [..._buses];

    // Solo aplicar filtros si el usuario ha interactuado
    if (_filtersApplied) {
      // Aplicar filtro de búsqueda
      if (_searchText.isNotEmpty) {
        filtered = filtered.where((bus) {
          final nombre = (bus['nombre'] ?? '').toString().toLowerCase();
          final search = _searchText.toLowerCase();
          return nombre.contains(search);
        }).toList();
      }

      // Aplicar filtro de ruta
      if (_selectedFilter != 'Todos') {
        filtered = filtered.where((bus) {
          return bus['nombre'] == _selectedFilter;
        }).toList();
      }

      // Aplicar ordenamiento
      switch (_selectedSort) {
        case 'Cercanía':
          if (_currentPosition != null) {
            filtered.sort((a, b) {
              final aOrigin = a['origin'] ?? {};
              final bOrigin = b['origin'] ?? {};
              final aDistance = _calculateDistance(
                _currentPosition!,
                aOrigin['lat'] ?? 0.0,
                aOrigin['log'] ??
                    0.0, // Nota: tu BD usa 'log' en lugar de 'lng'
              );
              final bDistance = _calculateDistance(
                _currentPosition!,
                bOrigin['lat'] ?? 0.0,
                bOrigin['log'] ?? 0.0,
              );
              return aDistance.compareTo(bDistance);
            });
          }
          break;

        case 'Tiempo':
          filtered.sort((a, b) {
            final aTime = _parseTime(a['horaSalida'] ?? '12:00 AM');
            final bTime = _parseTime(b['horaSalida'] ?? '12:00 AM');
            return aTime.hour.compareTo(bTime.hour);
          });
          break;
        case 'Nombre':
          filtered.sort((a, b) => (a['nombre'] ?? '')
              .toString()
              .compareTo((b['nombre'] ?? '').toString()));
          break;
        case 'Precio':
          filtered
              .sort((a, b) => (a['precio'] ?? 0).compareTo(b['precio'] ?? 0));
          break;
      }

      setState(() => _filteredBuses = filtered);
    }
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Barra de búsqueda
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
                      _searchText = value;
                      _applyFilters();
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
                          final horaLlegadaStr = bus['horaLlegada'];
                          if (horaLlegadaStr == null) return false;

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

                          // Para autobuses de hoy, mostrar solo los que aún no han llegado
                          if (busDate.year == now.year &&
                              busDate.month == now.month &&
                              busDate.day == now.day) {
                            final llegada = _parseTime(horaLlegadaStr);
                            final llegadaDateTime = DateTime(
                                busDate.year,
                                busDate.month,
                                busDate.day,
                                llegada.hour,
                                llegada.minute);
                            return llegadaDateTime.isAfter(now);
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
                                Builder(
                                  builder: (context) {
                                    final now = DateTime.now();
                                    final salida = _parseTime(
                                        bus['horaSalida'] ?? '12:00 AM');
                                    final llegada = _parseTime(
                                        bus['horaLlegada'] ?? '12:00 AM');
                                    final salidaDateTime = DateTime(
                                      busDate.year,
                                      busDate.month,
                                      busDate.day,
                                      salida.hour,
                                      salida.minute,
                                    );
                                    final llegadaDateTime = DateTime(
                                      busDate.year,
                                      busDate.month,
                                      busDate.day,
                                      llegada.hour,
                                      llegada.minute,
                                    );

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
                child: Row(
                  children: [
                    // Filtro por ruta
                    Expanded(
                        child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        hint: const Text('Buses'),
                        decoration: InputDecoration(
                          contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        items: [
                          const DropdownMenuItem(
                          value: 'Todos',
                          child: Text('Todos los buses'),
                          ),
                          const DropdownMenuItem(
                          value: 'Ninguno',
                          child: Text('No mostrar buses'),
                          ),
                          ..._buses
                            .map((bus) => bus['nombre'] as String)
                            .toSet()
                            .map((nombre) => DropdownMenuItem(
                              value: nombre,
                              child: Text(nombre),
                              ))
                            .toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                          _selectedFilter = value!;
                          if (_selectedFilter == 'Ninguno') {
                            _filteredBuses = [];
                          } else {
                            _applyFilters();
                          }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Ordenamiento
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSort,
                        hint: const Row(
                          children: [
                          Icon(Icons.filter_list, size: 18),
                          SizedBox(width: 8),
                          Text('Filtros'),
                          ],
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Cercanía',
                            child: Row(
                              children: [
                                Icon(Icons.near_me, size: 18),
                                SizedBox(width: 8),
                                Text('Cercanía'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Tiempo',
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 18),
                                SizedBox(width: 8),
                                Text('Hora salida'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Nombre',
                            child: Row(
                              children: [
                                Icon(Icons.sort_by_alpha, size: 18),
                                SizedBox(width: 8),
                                Text('Nombre'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Precio',
                            child: Row(
                              children: [
                                Icon(Icons.attach_money, size: 18),
                                SizedBox(width: 8),
                                Text('Precio'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSort = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de resultados
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredBuses.length,
                      itemBuilder: (context, index) {
                        final bus = _filteredBuses[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.directions_bus, size: 36),
                            title: Text(bus['nombre'] ?? 'Ruta sin nombre'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Salida: ${bus['horaSalida'] ?? 'N/A'}'),
                                Text('Llegada: ${bus['horaLlegada'] ?? 'N/A'}'),
                                Text(
                                    'Precio: \$${(num.tryParse(bus['precio']?.toString() ?? '')?.toStringAsFixed(2) ?? '0.00')}'),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              setState(() {
                                _selectedBus = bus;
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MapaScreen(selectedBus: bus),
                                ),
                              );
                            },
                          ),
                        );
                      },
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SeatSelectionScreen(
                              busData: bus,
                              onTicketPurchased: _fetchBuses,
                            ),
                          ),
                        );
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
