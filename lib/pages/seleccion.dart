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
  List<int> availableSeats = [];
  List<int> occupiedSeats = [];
  bool isLoading = false;
  bool isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    occupiedSeats = List<int>.from(widget.busData['occupiedSeats'] ?? []);
    availableSeats = List.generate(24, (index) => index + 1)
      ..removeWhere((seat) => occupiedSeats.contains(seat));
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => isLoading = false);
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      setState(() => isLoading = true);
      final doc = await FirebaseFirestore.instance
          .collection('busRoutes')
          .doc(widget.busData['id'])
          .get();

      if (!mounted) return;

      setState(() {
        occupiedSeats = List<int>.from(doc.data()?['occupiedSeats'] ?? []);
        availableSeats = List.generate(24, (index) => index + 1)
          ..removeWhere((seat) => occupiedSeats.contains(seat));
      });
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar: $e')),
          );
        }
      });
    } finally {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => isLoading = false);
      });
    }
  }

  Future<void> _confirmPurchase() async {
    setState(() => isPurchasing = true);

    try {
      final boletos = selectedSeats
          .map((asiento) => Boleto(
                asiento: asiento,
                ruta: widget.busData['nombre'],
                fecha: DateTime.now(),
                hora: widget.busData['horaSalida'],
                precio: double.parse(widget.busData['precio'].toString()),
              ))
          .toList();

      // Navegar a TicketW y esperar resultado
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
        // Forzar una nueva carga de datos desde Firestore
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

  // Método auxiliar para construir los asientos
  Widget _buildSeat(int seatNumber) {
    final isAvailable = availableSeats.contains(seatNumber);
    final isSelected = selectedSeats.contains(seatNumber);

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() {
                if (isSelected) {
                  selectedSeats.remove(seatNumber);
                } else {
                  selectedSeats.add(seatNumber);
                }
              });
            }
          : null,
      child: Container(
        width: 55,
        height: 55,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.shade600
              : isAvailable
                  ? Colors.white
                  : Colors.grey.shade400,
          border: Border.all(
            color: isSelected
                ? Colors.blue.shade800
                : isAvailable
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
                      : isAvailable
                          ? Colors.black
                          : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

          // Asientos del autobús
          Expanded(
            child: ListView.builder(
              itemCount: availableSeats.length ~/ 2.5, 
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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SeatLegend(color: Colors.green, text: 'Disponible'),
                      SeatLegend(color: Colors.red, text: 'Ocupado'),
                      SeatLegend(color: Colors.blue, text: 'Seleccionado'),
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
                                'Asiento seleccionado: ${selectedSeats.join(', ')}',
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

                  // Layout del autobús
                  Expanded(child: _buildBusLayout()),

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
