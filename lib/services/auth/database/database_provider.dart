import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nau/models/documents.dart';
import 'package:nau/models/driver.dart';
import 'package:nau/services/auth/database/database_service.dart';

import '../../../models/ruta.dart';
import '../../ruta_database_service.dart';

class DatabaseProvider extends ChangeNotifier {
  /*
  Servicios de base de datos
  */
  final _db = DatabaseService();

  /*
  Perfil del conductor
  */

  // Obtener el perfil del conductor actual por su UID
  Future<DriverProfile?> driverProfile(String uid) => _db.getDriverFromFirebase(uid);

  // Guardar documento del conductor
  Future<void> saveDriverDoc({
    required String driverId,
    required String fileURL,
    required String status,
    required DateTime expiryDate,
    required String docType,
  }) =>
      _db.saveDriverDocument(
        driverId: driverId,
        fileURL: fileURL,
        status: status,
        expiryDate: Timestamp.fromDate(expiryDate),
        docType: docType,
      );

  // Obtener documento del conductor
  Future<UserDocument?> getDriverDoc(String driverId) => _db.getDriverDocument(driverId);

  /*
  Rutas
  */
  final RutaDatabaseService _rutaService = RutaDatabaseService();

  Stream<List<Ruta>> getRutasSugeridas() {
    return _rutaService.getRutasSugeridas();
  }
  
}
