import 'package:flutter/material.dart';

class RutasSugeridas extends StatelessWidget {
  final List<Map<String, String>> routes;

  const RutasSugeridas({super.key, required this.routes});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.directions_bus),
            title: Text('${route['origen']} ➡ ${route['destino']}'),
            subtitle: Text('Tiempo estimado: ${route['tiempo']}'),
          ),
        );
      },
    );
  }
}
