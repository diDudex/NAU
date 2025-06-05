import 'package:flutter/material.dart';
import 'package:nau/admin/bus_editor_screen.dart';
import 'package:nau/admin/routes.dart';
import 'package:nau/admin/driver_editor_screen.dart';
import 'package:nau/admin/horariospage.dart';


class PanelAdministrador extends StatelessWidget {
  const PanelAdministrador({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel del Administrador")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text("Autobuses"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusEditorScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Conductores"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriverEditorScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.alt_route),
            title: const Text("Rutas"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusRoutesPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text("Horarios"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HorariosPage()),
            ),
          ),
        ],
      ),
    );
  }
}
