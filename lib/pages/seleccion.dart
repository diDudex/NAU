import 'package:flutter/material.dart';
import 'package:nau/pages/confirmacionboleto.dart';
import 'package:nau/widgets/ticketw.dart';
import '../models/boleto.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  int? selectedSeat;
  final List<int> availableSeats = List.generate(24, (index) => index + 1); // Asientos 1 al 24

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tu asiento'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Toca un asiento disponible:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: availableSeats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final seatNumber = availableSeats[index];
                  final isSelected = selectedSeat == seatNumber;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSeat = seatNumber;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.green : Colors.black,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          seatNumber.toString(),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedSeat != null
                  ? () {
                      final boleto = Boleto(
                        asiento: selectedSeat!,
                        ruta: 'Angostura-Guamuchil',
                        fecha: DateTime.now(),
                        hora: '14:00',
                        precio: 50.0,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TicketW(),
                        ),
                      );
                    }
                  : null,
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
