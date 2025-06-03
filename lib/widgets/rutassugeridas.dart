import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RutasSugeridas extends StatelessWidget {
  final Function(Map<String, dynamic>)? onBusSelected;

  const RutasSugeridas({super.key, this.onBusSelected});

  // Función para convertir horaSalida a TimeOfDay
  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return null;
      
      final timePart = parts[0].split(':');
      if (timePart.length != 2) return null;
      
      int hour = int.parse(timePart[0]);
      final minute = int.parse(timePart[1]);
      final period = parts[1].toUpperCase();
      
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final currentTime = TimeOfDay.fromDateTime(now);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('busRoutes')
          .where('createdAt', isGreaterThanOrEqualTo: today)
          .where('createdAt', isLessThan: tomorrow.add(const Duration(days: 1)))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay rutas sugeridas.'));
        }

        // Filtrar rutas
        final routes = snapshot.data!.docs.where((doc) {
          final route = doc.data() as Map<String, dynamic>;
          final busDate = route['createdAt'] is Timestamp 
              ? (route['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(route['createdAt'].toString());
          
          if (busDate == null) return false;
          
          final horaSalidaStr = route['horaSalida'] as String? ?? '';
          final horaSalida = _parseTimeString(horaSalidaStr);
          
          if (horaSalida == null) return false;
          
          // Si es para mañana, mostrar siempre
          if (busDate.year == tomorrow.year && 
              busDate.month == tomorrow.month && 
              busDate.day == tomorrow.day) {
            return true;
          }
          
          // Si es para hoy, mostrar solo los que salen después de la hora actual
          final salidaDateTime = DateTime(
              busDate.year, busDate.month, busDate.day, 
              horaSalida.hour, horaSalida.minute);
          
          return salidaDateTime.isAfter(now);
        }).toList();

        if (routes.isEmpty) {
          return const Center(child: Text('No hay rutas disponibles.'));
        }

        // Ordenar por fecha y hora
        routes.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          
          final aDate = aData['createdAt'] is Timestamp 
              ? (aData['createdAt'] as Timestamp).toDate()
              : DateTime.parse(aData['createdAt'].toString());
          final bDate = bData['createdAt'] is Timestamp 
              ? (bData['createdAt'] as Timestamp).toDate()
              : DateTime.parse(bData['createdAt'].toString());
              
          final aTime = _parseTimeString(aData['horaSalida'] ?? '') ?? TimeOfDay(hour: 0, minute: 0);
          final bTime = _parseTimeString(bData['horaSalida'] ?? '') ?? TimeOfDay(hour: 0, minute: 0);
          
          final aDateTime = DateTime(aDate.year, aDate.month, aDate.day, aTime.hour, aTime.minute);
          final bDateTime = DateTime(bDate.year, bDate.month, bDate.day, bTime.hour, bTime.minute);
          
          return aDateTime.compareTo(bDateTime);
        });

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final route = routes[index].data() as Map<String, dynamic>;
            final docId = routes[index].id;
            final horaSalidaParsed = _parseTimeString(route['horaSalida'] ?? '');
            final busDate = route['createdAt'] is Timestamp 
                ? (route['createdAt'] as Timestamp).toDate()
                : DateTime.parse(route['createdAt'].toString());
            
            final routeWithId = {...route, 'id': docId};
            final isTomorrow = busDate.year == tomorrow.year && 
                             busDate.month == tomorrow.month && 
                             busDate.day == tomorrow.day;
            
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  if (onBusSelected != null) {
                    onBusSelected!(routeWithId);
                  }
                },
                child: ListTile(
                  leading: const Icon(Icons.directions_bus),
                  title: Text(
                    (() {
                      final nombre = route['nombre'] ?? '';
                      final partes = nombre.split('-');
                      final origen = partes.isNotEmpty ? partes.first : '';
                      final destino = partes.length > 1 ? partes.last : '';
                      return '$origen ➡ $destino';
                    })(),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hora de salida: ${route['horaSalida']}'),
                      Text('Fecha: ${DateFormat('dd/MM/yyyy').format(busDate)}'),
                      if (isTomorrow)
                        const Text('(Mañana)', style: TextStyle(color: Color.fromARGB(255, 63, 142, 67))),
                      if (horaSalidaParsed != null && !isTomorrow)
                        Text(
                          'Sale en ${_formatTimeUntilDeparture(horaSalidaParsed, currentTime)}',
                          style: TextStyle(color: Color.fromARGB(255, 80, 197, 86)),
                        ),
                    ],
                  ),
                  trailing: onBusSelected != null 
                      ? const Icon(Icons.chevron_right, color: Colors.grey)
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimeUntilDeparture(TimeOfDay departure, TimeOfDay now) {
    final totalDepartureMinutes = departure.hour * 60 + departure.minute;
    final totalNowMinutes = now.hour * 60 + now.minute;
    final difference = totalDepartureMinutes - totalNowMinutes;

    if (difference <= 0) return 'Ahora';
    if (difference < 60) return 'en $difference min';
    
    final hours = difference ~/ 60;
    final minutes = difference % 60;
    
    if (minutes == 0) return 'en $hours h';
    return 'en $hours h $minutes min';
  }
}