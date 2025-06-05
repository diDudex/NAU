import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DriverEditorScreen extends StatefulWidget {
  const DriverEditorScreen({super.key});

  @override
  State<DriverEditorScreen> createState() => _DriverEditorScreenState();
}

class _DriverEditorScreenState extends State<DriverEditorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Conductores")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Drivers').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final drivers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final data = drivers[index].data() as Map<String, dynamic>;
              final busId = data['busid'];

              return ListTile(
                leading: const Icon(Icons.directions_bus_filled),
                title: Text(data['name'] ?? 'Sin nombre'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Email: ${data['email'] ?? 'N/A'}"),
                    Text("Tel: ${data['phoneNumber'] ?? 'N/A'}"),
                    if (busId != null && busId.toString().isNotEmpty)
                      FutureBuilder<DocumentSnapshot>(
                        future: _firestore.collection('Bus').doc(busId).get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text("Bus asignado: ...");
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Text("Bus asignado: No encontrado");
                          }
                          final busData = snapshot.data!.data() as Map<String, dynamic>;
                          return Text("Bus asignado: ${busData['numBus'] ?? 'N/A'}");
                        },
                      )
                    else
                      const Text("Bus asignado: Ninguno"),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDriverDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDriverDialog(BuildContext context) {
    String nombre = '';
    String email = '';
    String telefono = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Agregar Conductor"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  onChanged: (value) => nombre = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (value) => email = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => telefono = value,
                ),
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
                if (nombre.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Por favor llena todos los campos.")),
                  );
                  return;
                }

                final docRef = _firestore.collection('Drivers').doc();
                await docRef.set({
                  'driverid': docRef.id,
                  'name': nombre,
                  'email': email,
                  'phoneNumber': telefono,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
