import 'package:flutter/material.dart';
import '../models/boleto.dart';

class SeatSelectionWidget extends StatefulWidget {
  final Map<String, dynamic> busData;
  final Function(List<Boleto> boletos) onPurchasePressed;
  final bool isLoading;
  final bool isPurchasing;

  const SeatSelectionWidget({
    super.key,
    required this.busData,
    required this.onPurchasePressed,
    this.isLoading = false,
    this.isPurchasing = false,
  });

  @override
  State<SeatSelectionWidget> createState() => _SeatSelectionWidgetState();
}

class _SeatSelectionWidgetState extends State<SeatSelectionWidget> {
  List<int> selectedSeats = [];

  List<int> get occupiedSeats => List<int>.from(widget.busData['occupiedSeats'] ?? []);

  List<int> get availableSeats {
    return List.generate(24, (index) => index + 1)
      ..removeWhere((seat) => occupiedSeats.contains(seat));
  }

  @override
  void didUpdateWidget(SeatSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busData != widget.busData) {
      // Deseleccionar asientos que ya no están disponibles
      selectedSeats.removeWhere((seat) => !availableSeats.contains(seat));
    }
  }

  Widget _buildSeat(int seatNumber) {
    final isAvailable = availableSeats.contains(seatNumber);
    final isSelected = selectedSeats.contains(seatNumber);

    return GestureDetector(
      onTap: isAvailable
          ? () => setState(() {
                if (isSelected) {
                  selectedSeats.remove(seatNumber);
                } else {
                  selectedSeats.add(seatNumber);
                }
              })
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
        child: Center(
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
      ),
    );
  }

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
          Container(
            height: 40,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
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
          Expanded(
            child: ListView.builder(
              itemCount: 6, // 6 filas (24 asientos / 4 por fila)
              itemBuilder: (context, rowIndex) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(children: [_buildSeat(rowIndex * 4 + 1), const SizedBox(width: 8), _buildSeat(rowIndex * 4 + 2)]),
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
                      Row(children: [_buildSeat(rowIndex * 4 + 3), const SizedBox(width: 8), _buildSeat(rowIndex * 4 + 4)]),
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

    return widget.isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.busData['nombre'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          'Precio: \$${(double.tryParse(widget.busData['precio'].toString())?.toStringAsFixed(2) ?? '0.00')}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SeatLegend(color: Colors.white, text: 'Disponible'),
                    SeatLegend(color: Colors.grey, text: 'Ocupado'),
                    SeatLegend(color: Colors.blue, text: 'Seleccionado'),
                  ],
                ),
                const SizedBox(height: 20),
                if (selectedSeats.isNotEmpty) ...[
                  Card(
                    color: Theme.of(context).colorScheme.onPrimary,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedSeats.length > 1
                                ? '${selectedSeats.length} asientos seleccionados'
                                : 'Asiento seleccionado',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Números: ${selectedSeats.join(', ')}'),
                          const SizedBox(height: 4),
                          Text('Total: \$${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const Text('Selecciona tus asientos:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildBusLayout(),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isPurchasing
                          ? Colors.grey
                          : selectedSeats.isNotEmpty
                              ? Colors.green
                              : Colors.grey.shade300,
                      foregroundColor: selectedSeats.isNotEmpty ? Colors.white : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: selectedSeats.isNotEmpty && !widget.isPurchasing
                        ? () {
                            final boletos = selectedSeats.map((asiento) => Boleto(
                              asiento: asiento,
                              ruta: widget.busData['nombre'],
                              fecha: DateTime.now(),
                              hora: widget.busData['horaSalida'],
                              precio: double.parse(widget.busData['precio'].toString()),
                            )).toList();

                            widget.onPurchasePressed(boletos);
                          }
                        : null,
                    child: widget.isPurchasing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            selectedSeats.isEmpty
                                ? 'Selecciona un asiento'
                                : 'Comprar ${selectedSeats.length} boleto(s)',
                            style: const TextStyle(fontSize: 18)),
                  ),
                ),
              ],
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