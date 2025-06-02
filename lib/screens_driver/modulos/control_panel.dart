import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final bool isOnTrip;
  final VoidCallback onToggleTrip;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int passengersCount;

  const ControlPanel({
    super.key,
    required this.isOnTrip,
    required this.onToggleTrip,
    required this.onIncrement,
    required this.onDecrement,
    required this.passengersCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTripButton(context),
            if (isOnTrip) ...[
              const SizedBox(height: 20),
              _buildPassengerControls(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(isOnTrip ? Icons.stop : Icons.play_arrow),
      label: Text(isOnTrip ? 'Finalizar Viaje' : 'Iniciar Viaje'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isOnTrip ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: onToggleTrip,
    );
  }

  Widget _buildPassengerControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Pasajeros actuales:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle),
              color: Colors.red,
              onPressed: onDecrement,
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                '$passengersCount',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              color: Colors.green,
              onPressed: onIncrement,
            ),
          ],
        ),
      ],
    );
  }
}