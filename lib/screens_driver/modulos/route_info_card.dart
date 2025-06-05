import 'package:flutter/material.dart';

class RouteInfoCard extends StatelessWidget {
  final bool isOnTrip;
  final String routeName;
  final String schedule;
  final String busNumber;
  final String tripDuration;

  const RouteInfoCard({
    super.key,
    required this.isOnTrip,
    required this.routeName,
    required this.schedule,
    required this.busNumber,
    required this.tripDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  routeName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Chip(
                  label: Text(
                    isOnTrip ? 'EN VIAJE' : 'EN ESPERA',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: isOnTrip ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.schedule, 'Horario: $schedule'),
            const SizedBox(height: 5),
            _buildInfoRow(Icons.directions_bus, 'Autobús: $busNumber'),
            if (isOnTrip) ...[
              const SizedBox(height: 10),
              _buildInfoRow(Icons.timer, 'Duración: $tripDuration'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color.fromARGB(255, 78, 132, 63)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Color.fromARGB(255, 78, 132, 63))),
      ],
    );
  }
}