import 'package:flutter/material.dart';

class Walletscreen extends StatelessWidget {
  const Walletscreen({super.key});

  final double saldo = 0.0;
  final List<Map<String, String>> movimientos = const [
    {
      'camion': 'Camion 4',
      'destino': 'Guamuchil',
      'asiento': '12A',
      'fecha': '26 mayo',
      'monto': '0.00',
    },
    {
      'camion': 'Camion 4',
      'destino': 'Angostura',
      'asiento': '',
      'fecha': '26 mayo',
      'monto': '0.00',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monedero Electrónico'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'NAU CARD',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Tarjeta visual
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Image.asset(
                    'assets/bus_card.png', // Asegúrate de tener esta imagen
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '\$${saldo.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                // Agregar dinero lógica aquí
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'Agregar Dinero',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Movimientos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: movimientos.length,
                itemBuilder: (context, index) {
                  final mov = movimientos[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mov['camion'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Destino: ${mov['destino']}'),
                            if ((mov['asiento'] ?? '').isNotEmpty)
                              Text('Asiento: ${mov['asiento']}'),
                            Text(mov['fecha'] ?? ''),
                          ],
                        ),
                        const Spacer(),
                        Text('\$${mov['monto']}'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
