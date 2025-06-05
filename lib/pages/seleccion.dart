import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nau/widgets/ticketw.dart';
import '../models/boleto.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> busData;
  final Function() onTicketPurchased;

  const SeatSelectionScreen(
      {super.key, required this.busData, required this.onTicketPurchased});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<int> selectedSeats = [];
  Map<int, bool> seatAvailability = {};
  bool isLoading = false;
  bool isPurchasing = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Datos adicionales
  Map<String, dynamic>? _rutaData;
  Map<String, dynamic>? _horarioData;

  @override
  void initState() {
    super.initState();
    _loadBusData();
  }

  Future<void> _loadBusData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // 1. Obtener datos completos del bus seleccionado
      final busDoc =
          await _firestore.collection('Bus').doc(widget.busData['id']).get();
      if (!busDoc.exists) {
        throw Exception('El bus no existe');
      }
      final busData = busDoc.data()!;

      // 2. Obtener datos de la ruta asociada
      if (busData['rutasid'] != null) {
        final rutaDoc =
            await _firestore.collection('Rutas').doc(busData['rutasid']).get();
        if (rutaDoc.exists) {
          _rutaData = rutaDoc.data()!;
          _rutaData!['id'] = rutaDoc.id;
        }
      }

      // 3. Obtener datos del horario asociado
      if (busData['horarios'] is List &&
          (busData['horarios'] as List).isNotEmpty) {
        final horarioId = (busData['horarios'] as List).first;
        final horarioDoc =
            await _firestore.collection('Horarios').doc(horarioId).get();
        if (horarioDoc.exists) {
          _horarioData = horarioDoc.data()!;
          _horarioData!['id'] = horarioDoc.id;
        }
      }

      // 4. Obtener disponibilidad de asientos
      final seatsData = busData['asientos'] as Map<String, dynamic>? ?? {};
      seatAvailability = {
        for (var entry in seatsData.entries)
          int.parse(entry.key): entry.value as bool
      };

      // Asegurar todos los asientos (1-24)
      for (int i = 1; i <= 24; i++) {
        seatAvailability.putIfAbsent(i, () => false);
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadBusData();
  }

  Future<void> _confirmPurchase() async {
    if (selectedSeats.isEmpty) return;

    setState(() => isPurchasing = true);

    try {
      // Crear boletos con los datos actualizados
      final boletos = selectedSeats
          .map((asiento) => Boleto(
                asiento: asiento,
                ruta: _rutaData?['nombre'] ?? 'Ruta no disponible',
                fecha: DateTime.now(),
                hora: _horarioData?['horaSalida'] ?? 'Hora no disponible',
                precio: double.parse(_rutaData?['precio']?.toString() ?? '0.0'),
              ))
          .toList();

      // Actualizar asientos en Firestore
      final batch = _firestore.batch();
      final busRef = _firestore.collection('Bus').doc(widget.busData['id']);

      for (var seat in selectedSeats) {
        batch.update(busRef, {'asientos.$seat': true});
      }

      await batch.commit();

      // Mostrar tickets
      final success = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => TicketW(
                boletos: boletos,
                busRouteId: widget.busData['id'],
                onTicketPurchased: () {
                  widget.onTicketPurchased();
                  _refreshData();
                },
              ),
            ),
          ) ??
          false;

      if (success && mounted) {
        await _refreshData();
        setState(() => selectedSeats.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${boletos.length} boleto(s) comprado(s)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isPurchasing = false);
      }
    }
  }

  // Método para construir el layout del autobús
  // Este método crea la estructura visual del autobús con los asientos
  Widget _buildBusLayout() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Column(
        children: [
          // Cabina del conductor
          Container(
            height: 40,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.airline_seat_recline_normal,
                    color: Colors.grey.shade600, size: 24),
                const SizedBox(width: 8),
                Text(
                  'CONDUCTOR',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Asientos del autobús con pasillo central
          Expanded(
            child: ListView.builder(
              itemCount: 6, // 6 filas (4 asientos por fila = 24 total)
              itemBuilder: (context, rowIndex) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lado izquierdo (2 asientos)
                      Row(
                        children: [
                          _buildSeat((rowIndex * 4) + 1),
                          const SizedBox(width: 8),
                          _buildSeat((rowIndex * 4) + 2),
                        ],
                      ),

                      // Pasillo
                      SizedBox(
                        width: 50,
                        height: 45,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 2,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey.shade300,
                                    Colors.grey.shade500,
                                    Colors.grey.shade300,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lado derecho (2 asientos)
                      Row(
                        children: [
                          _buildSeat((rowIndex * 4) + 3),
                          const SizedBox(width: 8),
                          _buildSeat((rowIndex * 4) + 4),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeat(int seatNumber) {
    final isOccupied =
        seatAvailability[seatNumber] == true; // true significa ocupado
    final isSelected = selectedSeats.contains(seatNumber);

    return GestureDetector(
      onTap: isOccupied
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  selectedSeats.remove(seatNumber);
                } else {
                  selectedSeats.add(seatNumber);
                }
              });
            },
      child: Container(
        width: 55,
        height: 55,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.shade600
              : isOccupied
                  ? Colors.grey.shade400
                  : Colors.white,
          border: Border.all(
            color: isSelected
                ? Colors.blue.shade800
                : isOccupied
                    ? Colors.grey.shade600
                    : Colors.grey.shade600,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Número del asiento
            Center(
              child: Text(
                seatNumber.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : isOccupied
                          ? Colors.grey.shade600
                          : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final precio =
        double.tryParse(_rutaData?['precio']?.toString() ?? '0.0') ?? 0.0;
    final totalPrice =
        selectedSeats.isNotEmpty ? precio * selectedSeats.length : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Asientos - ${_rutaData?['nombre'] ?? 'Ruta'}'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del viaje
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _rutaData?['nombre'] ?? 'Ruta no disponible',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Salida: ${_horarioData?['horaSalida'] ?? 'Hora no disponible'}'),
                              Text(
                                  'Llegada: ${_horarioData?['horaLlegada'] ?? 'Hora no disponible'}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Precio unitario: \$${precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Leyenda de asientos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SeatLegend(color: Colors.white, text: 'Disponible'),
                      SeatLegend(color: Colors.grey.shade600, text: 'Ocupado'),
                      const SeatLegend(
                          color: Colors.blue, text: 'Seleccionado'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Resumen de selección
                  if (selectedSeats.isNotEmpty) ...[
                    Card(
                      color: Theme.of(context).colorScheme.onPrimary,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (selectedSeats.length > 1) ...[
                              Text(
                                'Cantidad de asientos: ${selectedSeats.length}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Asientos seleccionados: ${selectedSeats.join(', ')}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ] else ...[
                              Text(
                                'Asiento seleccionado: ${selectedSeats.first}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Total: \$${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const Text(
                    'Selecciona tus asientos:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // StreamBuilder para actualización en tiempo real
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: _firestore
                          .collection('Bus')
                          .doc(widget.busData['id'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Center(
                              child: Text('No se encontraron datos'));
                        }

                        // Actualizar disponibilidad de asientos
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final seatsData =
                            data['asientos'] as Map<String, dynamic>? ?? {};

                        seatAvailability = {
                          for (var entry in seatsData.entries)
                            int.parse(entry.key): entry.value as bool
                        };

                        // Asegurar todos los asientos (1-24)
                        for (int i = 1; i <= 24; i++) {
                          seatAvailability.putIfAbsent(i, () => false);
                        }

                        return _buildBusLayout();
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                  // Botón de confirmación
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPurchasing
                            ? Colors.grey
                            : selectedSeats.isNotEmpty
                                ? Colors.green
                                : Colors.red,
                        foregroundColor: selectedSeats.isNotEmpty
                            ? Colors.white
                            : Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      onPressed: selectedSeats.isNotEmpty && !isPurchasing
                          ? _confirmPurchase
                          : null,
                      child: isPurchasing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              selectedSeats.isEmpty
                                  ? 'Selecciona al menos un asiento'
                                  : 'Confirmar ${selectedSeats.length} asiento(s)',
                              style: const TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class SeatLegend extends StatelessWidget {
  final Color color;
  final String text;

  const SeatLegend({
    super.key,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black),
          ),
        ),
        const SizedBox(width: 5),
        Text(text),
      ],
    );
  }
}
