import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ruta.dart';

class RutaDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Ruta>> getRutasSugeridas() {
    return _db.collection('rutas').snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return Ruta.fromMap(doc.data());
        }).toList();
      },
    );
  }
}
