import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BusEditorScreen extends StatefulWidget {
  const BusEditorScreen({super.key});

  @override
  State<BusEditorScreen> createState() => _BusEditorScreenState();
}

class _BusEditorScreenState extends State<BusEditorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Autobuses"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BusSearchDelegate(_firestore),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Bus').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final buses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final busDoc = buses[index];
              final bus = busDoc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text("Bus #${bus['numBus']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Estado: ${bus['estado']}"),
                      FutureBuilder(
                        future: _firestore
                            .collection('Drivers')
                            .doc(bus['driverId'])
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text("Conductor: Cargando...");
                          }
                          final driver = snapshot.data?.data();
                          return Text(
                              "Conductor: ${driver?['name'] ?? 'No encontrado'}");
                        },
                      ),
                      FutureBuilder(
                        future: _firestore
                            .collection('Rutas')
                            .doc(bus['rutasid'])
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text("Ruta: Cargando...");
                          }
                          final ruta = snapshot.data?.data();
                          return Text(
                              "Ruta: ${ruta?['nombre'] ?? 'No encontrada'}");
                        },
                      ),
                      if (bus['horarios'] != null &&
                          (bus['horarios'] as List).isNotEmpty)
                        Text(
                            "Horarios asignados: ${(bus['horarios'] as List).length}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditBusDialog(context, busDoc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteBus(busDoc.id),
                      ),
                    ],
                  ),
                ),
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

  Future<void> _deleteBus(String busId) async {
    try {
      await _firestore.collection('Bus').doc(busId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Autobús eliminado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar autobús: $e')),
      );
    }
  }

  void _showAddBusDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String numBus = '';
    String? selectedDriverId;
    String? selectedRouteId;
    List<String> selectedHorarios = [];
    String estado = 'activo';
    List<DocumentSnapshot> routeHorarios = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Agregar Nuevo Autobús"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Número de autobús*",
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Este campo es obligatorio';
                          }
                          return null;
                        },
                        onChanged: (value) => numBus = value,
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<QuerySnapshot>(
                        future: _firestore.collection('Drivers').get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          final drivers = snapshot.data!.docs;
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: "Conductor*",
                            ),
                            value: selectedDriverId,
                            validator: (value) => value == null
                                ? 'Seleccione un conductor'
                                : null,
                            items: drivers.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem(
                                value: doc.id,
                                child:
                                    Text('${data['name']} ${data['lastName']}'),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setStateDialog(() => selectedDriverId = value),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<QuerySnapshot>(
                        future: _firestore.collection('Rutas').get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          final routes = snapshot.data!.docs;
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: "Ruta*",
                            ),
                            value: selectedRouteId,
                            validator: (value) =>
                                value == null ? 'Seleccione una ruta' : null,
                            items: routes.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(data['nombre']),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              setStateDialog(() => selectedRouteId = value);
                              if (value != null) {
                                final horarios = await _firestore
                                    .collection('Horarios')
                                    .where('rutaId', isEqualTo: value)
                                    .get();
                                setStateDialog(() {
                                  routeHorarios = horarios.docs;
                                });
                              } else {
                                setStateDialog(() {
                                  routeHorarios = [];
                                  selectedHorarios = [];
                                });
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      if (selectedRouteId != null) ...[
                        FutureBuilder(
                          future: _firestore
                              .collection('Horarios')
                              .where('rutaId', isEqualTo: selectedRouteId)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            final horarios = snapshot.data!.docs;
                            if (horarios.isEmpty) {
                              return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    "No hay horarios disponibles para esta ruta",
                                    style: TextStyle(color: Colors.grey),
                                  ));
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Horarios disponibles*",
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(height: 8),
                                ...horarios.map((doc) {
                                  final data = doc.data();
                                  final fecha = data['fecha'] is Timestamp
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(data['fecha'].toDate())
                                      : '--/--/----';
                                  return CheckboxListTile(
                                    title: Text(
                                        "${data['horaInicio']} - ${data['horaFin']}"),
                                    subtitle: Text(fecha),
                                    value: selectedHorarios.contains(doc.id),
                                    onChanged: (value) {
                                      setStateDialog(() {
                                        if (value == true) {
                                          selectedHorarios.add(doc.id);
                                        } else {
                                          selectedHorarios.remove(doc.id);
                                        }
                                      });
                                    },
                                  );
                                }),
                                if (selectedHorarios.isEmpty)
                                  const Text(
                                    "Debe seleccionar al menos un horario",
                                    style: TextStyle(color: Colors.red),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Estado*",
                        ),
                        value: estado,
                        validator: (value) =>
                            value == null ? 'Seleccione un estado' : null,
                        items: const [
                          DropdownMenuItem(
                            value: 'activo',
                            child: Text('Activo'),
                          ),
                          DropdownMenuItem(
                            value: 'inactivo',
                            child: Text('Inactivo'),
                          ),
                          DropdownMenuItem(
                            value: 'mantenimiento',
                            child: Text('Mantenimiento'),
                          ),
                        ],
                        onChanged: (value) =>
                            setStateDialog(() => estado = value!),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      if (selectedHorarios.isEmpty && selectedRouteId != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Seleccione al menos un horario')),
                        );
                        return;
                      }

                      try {
                        final asientos = {
                          for (var i = 1; i <= 24; i++) '$i': false
                        };

                        final busRef = await _firestore.collection('Bus').add({
                          'numBus': numBus,
                          'driverId': selectedDriverId,
                          'rutasid': selectedRouteId,
                          'horarios': selectedHorarios,
                          'asientos': asientos,
                          'ubicacion': {
                            'lat': 0,
                            'lng': 0,
                            'timestamp': FieldValue.serverTimestamp(),
                          },
                          'estado': estado,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        await busRef.update({'busid': busRef.id});

                        // Asignar el busid al conductor seleccionado
                        if (selectedDriverId != null) {
                          await _firestore
                              .collection('Drivers')
                              .doc(selectedDriverId)
                              .update({
                            'busid': busRef.id,
                          });
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Autobús creado exitosamente')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al crear autobús: $e')),
                        );
                      }
                    }
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditBusDialog(BuildContext context, DocumentSnapshot busDoc) {
    final bus = busDoc.data() as Map<String, dynamic>;
    final formKey = GlobalKey<FormState>();
    final numBusController = TextEditingController(text: bus['numBus']);
    String? selectedDriverId = bus['driverId'];
    String? selectedRouteId = bus['rutasid'];
    List<String> selectedHorarios = List.from(bus['horarios'] ?? []);
    String estado = bus['estado'] ?? 'activo';
    List<DocumentSnapshot> routeHorarios = [];

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder(
          future: Future.wait([
            _firestore.collection('Drivers').get(),
            _firestore.collection('Rutas').get(),
            _firestore
                .collection('Horarios')
                .where('rutaId', isEqualTo: selectedRouteId)
                .get(),
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return AlertDialog(
                title: const Text('Cargando...'),
                content: const CircularProgressIndicator(),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ],
              );
            }

            final results = snapshot.data!;
            final drivers = results[0].docs;
            final routes = results[1].docs;
            routeHorarios = results[2].docs;

            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  title: const Text('Editar Autobús'),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: numBusController,
                            decoration: const InputDecoration(
                              labelText: 'Número de Autobús*',
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Campo obligatorio' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedDriverId,
                            items: drivers.map((doc) {
                              final data = doc.data();
                              return DropdownMenuItem(
                                value: doc.id,
                                child:
                                    Text('${data['name']} ${data['lastName']}'),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setStateDialog(() => selectedDriverId = value),
                            decoration: const InputDecoration(
                              labelText: 'Conductor*',
                            ),
                            validator: (value) => value == null
                                ? 'Seleccione un conductor'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedRouteId,
                            items: routes.map((doc) {
                              final data = doc.data();
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(data['nombre']),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              setStateDialog(() => selectedRouteId = value);
                              if (value != null) {
                                final horarios = await _firestore
                                    .collection('Horarios')
                                    .where('rutaId', isEqualTo: value)
                                    .get();
                                setStateDialog(() {
                                  routeHorarios = horarios.docs;
                                  selectedHorarios = [];
                                });
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Ruta*',
                            ),
                            validator: (value) =>
                                value == null ? 'Seleccione una ruta' : null,
                          ),
                          const SizedBox(height: 16),
                          if (selectedRouteId != null) ...[
                            if (routeHorarios.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  "No hay horarios disponibles para esta ruta",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            if (routeHorarios.isNotEmpty) ...[
                              const Text('Horarios disponibles*',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              ...routeHorarios.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final fecha = data['fecha'] is Timestamp
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(data['fecha'].toDate())
                                    : '--/--/----';
                                return CheckboxListTile(
                                  title: Text(
                                      '${data['horaInicio']} - ${data['horaFin']}'),
                                  subtitle: Text(fecha),
                                  value: selectedHorarios.contains(doc.id),
                                  onChanged: (value) => setStateDialog(() {
                                    if (value == true) {
                                      selectedHorarios.add(doc.id);
                                    } else {
                                      selectedHorarios.remove(doc.id);
                                    }
                                  }),
                                );
                              }),
                              if (selectedHorarios.isEmpty)
                                const Text(
                                  "Debe seleccionar al menos un horario",
                                  style: TextStyle(color: Colors.red),
                                ),
                            ],
                            const SizedBox(height: 16),
                          ],
                          DropdownButtonFormField<String>(
                            value: estado,
                            items: const [
                              DropdownMenuItem(
                                value: 'activo',
                                child: Text('Activo'),
                              ),
                              DropdownMenuItem(
                                value: 'inactivo',
                                child: Text('Inactivo'),
                              ),
                              DropdownMenuItem(
                                value: 'mantenimiento',
                                child: Text('Mantenimiento'),
                              ),
                            ],
                            onChanged: (value) =>
                                setStateDialog(() => estado = value!),
                            decoration: const InputDecoration(
                              labelText: 'Estado*',
                            ),
                            validator: (value) =>
                                value == null ? 'Seleccione un estado' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          if (selectedHorarios.isEmpty &&
                              selectedRouteId != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Seleccione al menos un horario')),
                            );
                            return;
                          }

                          try {
                            await busDoc.reference.update({
                              'numBus': numBusController.text,
                              'driverId': selectedDriverId,
                              'rutasid': selectedRouteId,
                              'horarios': selectedHorarios,
                              'estado': estado,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Autobús actualizado exitosamente')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Error al actualizar autobús: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class BusSearchDelegate extends SearchDelegate {
  final FirebaseFirestore firestore;

  BusSearchDelegate(this.firestore);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('Bus')
          .where('numBus', isGreaterThanOrEqualTo: query)
          .where('numBus', isLessThan: '${query}z')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs;

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final bus = results[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text("Bus #${bus['numBus']}"),
              subtitle: Text("Estado: ${bus['estado']}"),
              onTap: () {
                close(context, results[index]);
              },
            );
          },
        );
      },
    );
  }
}
