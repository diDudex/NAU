import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener viajes de un conductor específico
  Stream<List<Trip>> getDriverTrips(String driverId) {
    return _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .orderBy('endTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Trip.fromFirestore(doc))
            .toList());
  }

  // Obtener un viaje específico (opcional)
  Future<Trip> getTripById(String tripId) async {
    final doc = await _firestore.collection('trips').doc(tripId).get();
    return Trip.fromFirestore(doc);
  }
}