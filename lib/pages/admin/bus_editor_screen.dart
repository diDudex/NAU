import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BusEditorScreen extends StatefulWidget {
  const BusEditorScreen({super.key});

  @override
  State<BusEditorScreen> createState() => _BusEditorScreenState();
}

class _BusEditorScreenState extends State<BusEditorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Autobuses")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Bus').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final buses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text("Bus #${bus['numBus']}"),
                subtitle: Text("Conductor ID: ${bus['driverId']}\nRuta ID: ${bus['busRouteId']}"),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBusDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddBusDialog(BuildContext context) async {
    String? selectedDriverId;
    String? selectedRouteId;
    List<String> selectedHorarios = [];
    String numBus = "";

    final driversSnapshot = await _firestore.collection('Drivers').get();
    final routesSnapshot = await _firestore.collection('BusRoutes').get();
    final horariosSnapshot = await _firestore.collection('Horarios').get();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Agregar Autobús"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: "Número de autobús"),
                    onChanged: (value) => numBus = value,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedDriverId,
                    decoration: const InputDecoration(labelText: "Seleccionar conductor"),
                    items: driversSnapshot.docs.map((doc) {
                      final data = doc.data();
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['nombre'] ?? doc.id),
                      );
                    }).toList(),
                    onChanged: (value) => setStateDialog(() => selectedDriverId = value),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedRouteId,
                    decoration: const InputDecoration(labelText: "Seleccionar ruta"),
                    items: routesSnapshot.docs.map((doc) {
                      final data = doc.data();
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['nombreRuta'] ?? doc.id),
                      );
                    }).toList(),
                    onChanged: (value) => setStateDialog(() => selectedRouteId = value),
                  ),
                  const SizedBox(height: 10),
                  const Text("Seleccionar horarios:"),
                  ...horariosSnapshot.docs.map((doc) {
                    final data = doc.data();
                    final id = doc.id;
                    final hora = data['salida']?.toDate().toString() ?? 'Sin hora';
                    return CheckboxListTile(
                      value: selectedHorarios.contains(id),
                      title: Text("Horario: $hora"),
                      onChanged: (value) {
                        setStateDialog(() {
                          if (value == true) {
                            selectedHorarios.add(id);
                          } else {
                            selectedHorarios.remove(id);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancelar"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text("Guardar"),
                onPressed: () async {
                  // Crear asientos en false por default
                  final asientos = {for (var i = 1; i <= 32; i++) '$i': false};

                  await _firestore.collection('Bus').add({
                    'numBus': numBus,
                    'driverId': selectedDriverId,
                    'busRouteId': selectedRouteId,
                    'horarios': selectedHorarios,
                    'asientos': asientos,
                    'ubicacion': {
                      'lat': 0,
                      'lng': 0,
                      'timestamp': FieldValue.serverTimestamp(),
                    }
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
      },
    );
  }
}
