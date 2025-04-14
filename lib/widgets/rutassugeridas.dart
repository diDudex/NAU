import 'package:flutter/material.dart';

class RutasSugeridas extends StatelessWidget {
  final List<Map<String, String>> routes;

  const RutasSugeridas({Key? key, required this.routes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Icon(Icons.directions_bus),
            title: Text('${route['origen']} ➡ ${route['destino']}'),
            subtitle: Text('Tiempo estimado: ${route['tiempo']}'),
          ),
        );
      },
    );
  }
}
