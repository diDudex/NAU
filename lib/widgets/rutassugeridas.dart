import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RutasSugeridas extends StatefulWidget {
  final Function(Map<String, dynamic>)? onBusSelected;

  const RutasSugeridas({super.key, this.onBusSelected});

  @override
  State<RutasSugeridas> createState() => _RutasSugeridasState();
}

class _RutasSugeridasState extends State<RutasSugeridas> {
  final Random _random = Random();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _rutasCompletas = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _dateFormatInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting().then((_) {
      _cargarRutasCompletas();
    });
  }

  Future<void> _initializeDateFormatting() async {
    setState(() {
      _dateFormatInitialized = true;
    });
  }

  Future<void> _cargarRutasCompletas() async {
    if (!_dateFormatInitialized) return;

    try {
      // 1. Obtener todas las rutas disponibles
      final rutasSnapshot = await _firestore.collection('Rutas').get();

      // 2. Para cada ruta, obtener sus horarios y buses asociados
      List<Map<String, dynamic>> rutasCompletas = [];

      for (var rutaDoc in rutasSnapshot.docs) {
        final rutaData = rutaDoc.data();
        rutaData['id'] = rutaDoc.id;

        // Obtener horarios asociados (como en tu imagen de Horarios)
        final horariosQuery = await _firestore
            .collection('Horarios')
            .where('rutaId', isEqualTo: rutaDoc.id)
            .get();

        final horarios = horariosQuery.docs.map((doc) {
          final horarioData = doc.data();
          horarioData['id'] = doc.id;
          return horarioData;
        }).toList();

        rutaData['horarios'] = horarios;

        // Obtener buses asociados (como en tu imagen de Bus)
        final busesQuery = await _firestore
            .collection('Bus')
            .where('rutasid', isEqualTo: rutaDoc.id)
            .get();

        final buses = busesQuery.docs.map((doc) {
          final busData = doc.data();
          busData['id'] = doc.id;
          return busData;
        }).toList();

        rutaData['buses'] = buses;

        rutasCompletas.add(rutaData);
      }

      setState(() {
        _rutasCompletas = rutasCompletas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al cargar rutas: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dateFormatInitialized || _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_rutasCompletas.isEmpty) {
      return const Center(child: Text('No hay rutas disponibles'));
    }

    // Seleccionar 3 rutas al azar
    final rutasAleatorias = _obtenerRutasAleatorias(_rutasCompletas, 3);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rutasAleatorias.length,
      itemBuilder: (context, index) {
        final ruta = rutasAleatorias[index];
        final nombreRuta = ruta['nombre'] ?? 'Ruta sin nombre';
        final horarios = ruta['horarios'] as List;
        final buses = ruta['buses'] as List;

        // Tomamos el primer horario disponible para mostrar
        final horarioPrincipal = horarios.isNotEmpty ? horarios[0] : {};
        final fechaHorario = horarioPrincipal['fecha'] != null
            ? _parsearFecha(horarioPrincipal['fecha'])
            : null;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => widget.onBusSelected?.call(ruta),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre de la ruta (formateado)
                  Text(
                    _formatearNombreRuta(nombreRuta),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Detalles de origen y destino
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Origen: ${horarioPrincipal['origen'] ?? 'No especificado'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.flag, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Destino: ${horarioPrincipal['destino'] ?? 'No especificado'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fecha y hora
                  if (fechaHorario != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha: ${horarioPrincipal['fecha'] is Timestamp ? (horarioPrincipal['fecha'] as Timestamp).toDate().toString().split(' ')[0] : (horarioPrincipal['fecha']?.toString().split(' ')[0] ?? '--/--/----')}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Hora: ${horarioPrincipal['horaInicio'] ?? '--:--'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),

                  // Información de buses disponibles
                  Row(
                    children: [
                      const Icon(Icons.directions_bus, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Buses disponibles: ${buses.length}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  buses.isNotEmpty ? Colors.green : Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  DateTime _parsearFecha(dynamic fecha) {
    try {
      if (fecha is Timestamp) {
        return fecha.toDate();
      } else if (fecha is String) {
        return DateTime.parse(fecha);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  List<Map<String, dynamic>> _obtenerRutasAleatorias(
      List<Map<String, dynamic>> todasLasRutas, int cantidad) {
    if (todasLasRutas.length <= cantidad) return todasLasRutas;
    final shuffled = List.of(todasLasRutas)..shuffle(_random);
    return shuffled.take(cantidad).toList();
  }

  String _formatearNombreRuta(String nombre) {
    final partes = nombre.split('-');
    final origen = partes.isNotEmpty
        ? partes.first[0].toUpperCase() +
            partes.first.substring(1).toLowerCase()
        : 'Origen';
    final destino = partes.length > 1
        ? partes.last[0].toUpperCase() + partes.last.substring(1).toLowerCase()
        : 'Destino';
    return '$origen → $destino';
  }
}
