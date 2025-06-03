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

  @override
  void initState() {
    super.initState();
    _loadSeatData();
  }

  Future<void> _loadSeatData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => isLoading = true);
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('busRoutes')
          .doc(widget.busData['id'])
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final seatsData = data['seats'] as Map<String, dynamic>? ?? {};

        setState(() {
          // Convertir los datos de Firestore a nuestro mapa
          seatAvailability = {
            for (var entry in seatsData.entries)
              int.parse(entry.key): entry.value as bool
          };

          // Asegurarnos de tener todos los asientos (1-24)
          for (int i = 1; i <= 24; i++) {
            seatAvailability.putIfAbsent(
                i, () => false); // Por defecto disponibles
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar asientos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadSeatData();
  }

  Future<void> _confirmPurchase() async {
    if (selectedSeats.isEmpty) return;

    setState(() => isPurchasing = true);

    try {
      // Crear los boletos
      final boletos = selectedSeats
          .map((asiento) => Boleto(
                asiento: asiento,
                ruta: widget.busData['nombre'],
                fecha: DateTime.now(),
                hora: widget.busData['horaSalida'],
                precio: double.parse(widget.busData['precio'].toString()),
              ))
          .toList();

      // Actualizar los asientos en Firestore
      final batch = FirebaseFirestore.instance.batch();
      final busRef = FirebaseFirestore.instance
          .collection('busRoutes')
          .doc(widget.busData['id']);

      // Marcar asientos como ocupados
      for (var seat in selectedSeats) {
        batch.update(busRef, {'seats.$seat': true});
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
    final totalPrice = selectedSeats.isNotEmpty
        ? (double.tryParse(widget.busData['precio'].toString()) ?? 0.0) *
            selectedSeats.length
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Asientos - ${widget.busData['nombre']}'),
        centerTitle: true,
      ),
      body: Padding(
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
                      widget.busData['nombre'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Salida: ${widget.busData['horaSalida']}'),
                        Text('Llegada: ${widget.busData['horaLlegada']}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Precio unitario: \$${(double.tryParse(widget.busData['precio'].toString())?.toStringAsFixed(2) ?? '0.00')}',
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
                const SeatLegend(color: Colors.blue, text: 'Seleccionado'),
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Asientos seleccionados: ${selectedSeats.join(', ')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ] else ...[
                        Text(
                          'Asiento seleccionado: ${selectedSeats.join(', ')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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

            // StreamBuilder para la lista de asientos
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('busRoutes')
                    .doc(widget.busData['id'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.data() == null) {
                    return const Center(child: Text('No se encontraron datos'));
                  }

                  // Procesar datos y actualizar estado
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final seatsData =
                      data['seats'] as Map<String, dynamic>? ?? {};

                  // Actualizar el mapa de disponibilidad
                  seatAvailability = {
                    for (var entry in seatsData.entries)
                      int.parse(entry.key): entry.value as bool
                  };

                  // Asegurar que tenemos todos los asientos (1-24)
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
                  foregroundColor:
                      selectedSeats.isNotEmpty ? Colors.white : Colors.red,
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
