import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nau/models/driver.dart';
import 'package:nau/models/documents.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // CONDUCTOR - Perfil
  // =========================

  // Guardar información del conductor
  Future<void> saveDriverInfoInFirebase({
    required String name,
    required String lastName,
    required String email,
  }) async {
    final uid = _auth.currentUser!.uid;

    DriverProfile driver = DriverProfile(
      uid: uid,
      name: name,
      lastName: lastName,
      email: email,
      profilePic: '',
    );

    final driverMap = driver.toMap();
    await _db.collection('Drivers').doc(uid).set(driverMap);
  }

  // Obtener información del conductor
  Future<DriverProfile?> getDriverFromFirebase(String uid) async {
    try {
      DocumentSnapshot driverDoc = await _db.collection('Drivers').doc(uid).get();
      return DriverProfile.fromDocument(driverDoc);
    } catch (e) {
      print('Error obteniendo perfil de conductor: $e');
      return null;
    }
  }

  // Actualizar datos del conductor
  Future<void> updateDriverField(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('Drivers').doc(uid).update(data);
    } catch (e) {
      print('Error actualizando campo del conductor: $e');
    }
  }

  // Verificar si un conductor ya existe
  Future<bool> doesDriverExist(String uid) async {
    DocumentSnapshot doc = await _db.collection('Drivers').doc(uid).get();
    return doc.exists;
  }

  // =========================
  // DOCUMENTOS DEL CONDUCTOR
  // =========================

  // Guardar documentos del conductor
  Future<void> saveDriverDocument({
    required String driverId,
    required String fileURL,
    required String status,
    required Timestamp expiryDate,
    required String docType,
  }) async {
    UserDocument doc = UserDocument(
      userid: driverId,
      fileURL: fileURL,
      status: status,
      expiryDate: expiryDate,
      docType: docType,
    );

    final docMap = doc.toMap();
    await _db.collection('DriverDocuments').doc(driverId).set(docMap);
  }

  // Obtener documentos del conductor
  Future<UserDocument?> getDriverDocument(String driverId) async {
    try {
      DocumentSnapshot doc = await _db.collection('DriverDocuments').doc(driverId).get();

      if (!doc.exists || doc.data() == null) {
        return UserDocument(
          userid: driverId,
          fileURL: '',
          status: 'sin documentos',
          expiryDate: Timestamp(0, 0),
          docType: '',
        );
      }

      return UserDocument.fromDocument(doc);
    } catch (e) {
      print('Error obteniendo documento del conductor: $e');
      return null;
    }
  }
}
