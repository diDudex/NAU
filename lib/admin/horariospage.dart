import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HorariosPage extends StatefulWidget {
  const HorariosPage({super.key});

  @override
  State<HorariosPage> createState() => _HorariosPageState();
}

class _HorariosPageState extends State<HorariosPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<TimeRange> _timeRanges = [TimeRange()];
  String? _selectedRouteId;
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _routes = [];
  Map<String, dynamic>? _selectedRouteDetails;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final routesSnapshot = await _firestore.collection('Rutas').get();
    setState(() {
      _routes = routesSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  Future<void> _selectRoute(String? routeId) async {
    if (routeId == null) {
      setState(() => _selectedRouteDetails = null);
      return;
    }

    final routeDoc = await _firestore.collection('Rutas').doc(routeId).get();
    setState(() {
      _selectedRouteDetails = routeDoc.data();
      if (_selectedRouteDetails != null && _selectedRouteDetails!['nombre'] != null) {
        final partes = (_selectedRouteDetails!['nombre'] as String).split('-');
        if (partes.length >= 2) {
          _selectedRouteDetails!['origen'] = partes.first.trim();
          _selectedRouteDetails!['destino'] = partes.last.trim();
        }
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(TimeRange range, bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          range.startTime = time;
        } else {
          range.endTime = time;
        }
      });
    }
  }

  void _addTimeRange() {
    setState(() => _timeRanges.add(TimeRange()));
  }

  void _removeTimeRange(int index) {
    if (_timeRanges.length > 1) {
      setState(() => _timeRanges.removeAt(index));
    }
  }

  Future<void> _saveSchedule() async {
    if (_selectedRouteId == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una ruta y fecha')),
      );
      return;
    }

    // Validar todos los rangos horarios
    for (var range in _timeRanges) {
      if (range.startTime == null || range.endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete todos los horarios')),
        );
        return;
      }

      final startHour = range.startTime!.hour;
      final startMinute = range.startTime!.minute;
      final endHour = range.endTime!.hour;
      final endMinute = range.endTime!.minute;

      if (endHour < startHour || (endHour == startHour && endMinute <= startMinute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La hora de llegada debe ser posterior a la de salida')),
        );
        return;
      }
    }

    try {
      final batch = _firestore.batch();
      final horariosRef = _firestore.collection('Horarios');

      for (var range in _timeRanges) {
        final horarioData = {
          'rutaId': _selectedRouteId,
          'fecha': Timestamp.fromDate(_selectedDate!),
          'horaInicio': '${range.startTime!.hour.toString().padLeft(2, '0')}:${range.startTime!.minute.toString().padLeft(2, '0')}',
          'horaFin': '${range.endTime!.hour.toString().padLeft(2, '0')}:${range.endTime!.minute.toString().padLeft(2, '0')}',
          'origen': _selectedRouteDetails?['origen'] ?? '',
          'destino': _selectedRouteDetails?['destino'] ?? '',
          'estado': 'pendiente',
          'createdAt': FieldValue.serverTimestamp(),
        };
        batch.set(horariosRef.doc(), horarioData);
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_timeRanges.length} horarios guardados exitosamente')),
      );

      // Resetear el formulario
      setState(() {
        _selectedRouteId = null;
        _selectedDate = null;
        _selectedRouteDetails = null;
        _timeRanges.clear();
        _timeRanges.add(TimeRange());
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar horarios: $e')),
      );
    }
  }

  Future<void> _deleteHorario(String horarioId) async {
    try {
      await _firestore.collection('Horarios').doc(horarioId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horario eliminado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar horario: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Horarios'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Lista de Horarios'),
              Tab(icon: Icon(Icons.add), text: 'Agregar Horarios'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña 1: Lista de horarios existentes
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('Horarios').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay Horarios disponibles'));
                }

                final horarios = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: horarios.length,
                  itemBuilder: (context, index) {
                    final horarioDoc = horarios[index];
                    final horario = horarioDoc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text('${horario['horaInicio']} - ${horario['horaFin']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ruta: ${horario['origen']} → ${horario['destino']}'),
                            if (horario['fecha'] is Timestamp)
                              Text('Fecha: ${DateFormat('dd/MM/yyyy').format(horario['fecha'].toDate())}'),
                            Text('Estado: ${horario['estado']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditHorarioDialog(context, horarioDoc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteHorario(horarioDoc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Pestaña 2: Agregar nuevos horarios
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Ruta*',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedRouteId,
                    items: _routes.map<DropdownMenuItem<String>>((route) => DropdownMenuItem<String>(
                      value: route['id'] as String,
                      child: Text('${route['nombre']}'),
                    )).toList(),
                    onChanged: (value) {
                      setState(() => _selectedRouteId = value);
                      _selectRoute(value);
                    },
                    validator: (value) => value == null ? 'Seleccione una ruta' : null,
                  ),
                  const SizedBox(height: 16),
                  if (_selectedRouteDetails != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Detalles de la Ruta',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('Origen: ${_selectedRouteDetails!['origen']}'),
                            Text('Destino: ${_selectedRouteDetails!['destino']}'),
                            Text('Duración: ${_selectedRouteDetails!['duracionEstimada']} min'),
                            Text('Distancia: ${_selectedRouteDetails!['distancia']} km'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha del viaje*',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_selectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                              : 'Seleccionar fecha'),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Horarios:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._timeRanges.asMap().entries.map((entry) {
                    final index = entry.key;
                    final range = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Horario ${index + 1}:',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (_timeRanges.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeTimeRange(index),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTimePicker(
                                    'Salida',
                                    range.startTime,
                                    () => _pickTime(range, true),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTimePicker(
                                    'Llegada',
                                    range.endTime,
                                    () => _pickTime(range, false),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.topCenter,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar otro horario'),
                      onPressed: _addTimeRange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveSchedule,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Guardar Todos los Horarios'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time != null ? time.format(context) : 'Seleccionar hora'),
            const Icon(Icons.schedule),
          ],
        ),
      ),
    );
  }

  void _showEditHorarioDialog(BuildContext context, DocumentSnapshot horarioDoc) {
    final horario = horarioDoc.data() as Map<String, dynamic>;
    final formKey = GlobalKey<FormState>();
    TimeOfDay? horaInicio;
    TimeOfDay? horaFin;
    DateTime? fecha;

    // Parsear hora de inicio
    if (horario['horaInicio'] is String) {
      final parts = (horario['horaInicio'] as String).split(':');
      if (parts.length >= 2) {
        final hourStr = parts[0].split(' ').first;
        final minuteStr = parts[1].split(' ').first;
        horaInicio = TimeOfDay(hour: int.parse(hourStr), minute: int.parse(minuteStr));
      }
    }

    // Parsear hora de fin
    if (horario['horaFin'] is String) {
      final parts = (horario['horaFin'] as String).split(':');
      if (parts.length >= 2) {
        final hourStr = parts[0].split(' ').first;
        final minuteStr = parts[1].split(' ').first;
        horaFin = TimeOfDay(hour: int.parse(hourStr), minute: int.parse(minuteStr));
      }
    }

    // Parsear fecha
    if (horario['fecha'] is Timestamp) {
      fecha = (horario['fecha'] as Timestamp).toDate();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Horario'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: horaInicio ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setStateDialog(() => horaInicio = time);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Hora de salida*',
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(horaInicio != null ? horaInicio!.format(context) : 'Seleccionar hora'),
                              const Icon(Icons.schedule),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: horaFin ?? TimeOfDay.now(),
                          );
                          if (time != null) {
                            setStateDialog(() => horaFin = time);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Hora de llegada*',
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(horaFin != null ? horaFin!.format(context) : 'Seleccionar hora'),
                              const Icon(Icons.schedule),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: fecha ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setStateDialog(() => fecha = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha*',
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(fecha != null ? DateFormat('dd/MM/yyyy').format(fecha!) : 'Seleccionar fecha'),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
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
                    if (horaInicio == null || horaFin == null || fecha == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Complete todos los campos')),
                      );
                      return;
                    }

                    try {
                      await horarioDoc.reference.update({
                        'horaInicio': '${horaInicio!.hour.toString().padLeft(2, '0')}:${horaInicio!.minute.toString().padLeft(2, '0')}',
                        'horaFin': '${horaFin!.hour.toString().padLeft(2, '0')}:${horaFin!.minute.toString().padLeft(2, '0')}',
                        'fecha': Timestamp.fromDate(fecha!),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Horario actualizado exitosamente')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al actualizar horario: $e')),
                      );
                    }
                  },
                  child: const Text('Guardar Cambios'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class TimeRange {
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  TimeRange({this.startTime, this.endTime});
}