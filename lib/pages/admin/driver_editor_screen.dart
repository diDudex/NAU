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
              return ListTile(
                leading: const Icon(Icons.directions_bus_filled),
                title: Text(data['name'] ?? 'Sin nombre'),
                subtitle: Text("Email: ${data['email'] ?? 'N/A'}\nTel: ${data['phoneNumber'] ?? 'N/A'}"),
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

                await _firestore.collection('Drivers').add({
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
