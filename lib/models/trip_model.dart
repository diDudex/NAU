import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String busId;
  final String busNumber; // Número identificador del autobús
  final String driverId;
  final DateTime startTime;
  final DateTime endTime;
  final int ticketsSold;
  final String routeName;

  Trip({
    required this.id,
    required this.busId,
    required this.busNumber,
    required this.driverId,
    required this.startTime,
    required this.endTime,
    required this.ticketsSold,
    required this.routeName,
  });

  // Duración calculada del viaje
  Duration get duration => endTime.difference(startTime);

  // Formato de hora para mostrar
  String get formattedStartTime => 
      '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
  
  String get formattedEndTime => 
      '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';
  
  // Duración formateada
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      busId: data['busId'],
      busNumber: data['busNumber'],
      driverId: data['driverId'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      ticketsSold: data['ticketsSold'],
      routeName: data['routeName'],
    );
  }
}