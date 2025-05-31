import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nau/models/documents.dart';
import 'package:nau/models/user.dart';
import 'package:nau/services/auth/auth_services.dart';
import 'package:nau/services/auth/database/database_service.dart';

import '../../../models/ruta.dart';
import '../../ruta_database_service.dart';
/*
  DatabaseProvider
    Este proveedor sirve para separar el manejo de datos de Firestore y 
    la interfaz de usuario de nuestra aplicación.
    -----------------------------------------------------------------------------------------------
    - Este proveedor sirve para separar el manejo de datos de Firestore y 
    la interfaz de usuario de la aplicación
    - El DatabaseProvider procesa los datos para mostrarlos en la aplicación.

    -----------------------------------------------------------------------------------------------
    Esto es para hacer que nuestro código sea mucho más modular, más limpio y más fácil de leer y probar.

    A medida que aumenta el número de páginas, necesitamos que este proveedor administre 
    adecuadamente los diferentes estados de la aplicación.

    Además, si un día decidimos cambiar su backend (de Firebase a otra cosa, entonces es 
    mucho más fácil administrar y cambiar diferentes bases de datos)
*/

class DatabaseProvider extends ChangeNotifier {
  /*
  Services

  */

  //obtener db y auth services
  final _db = DatabaseService();
  /*
  Perfil de usuario

  */

  //obtener el perfil del usuario actual por su uid
  Future<UserProfile?> userProfile(String uid, ) => _db.getUserFromFirebase(uid);

  Future<void> saveDoc({
    required String userid,
    required String fileURL,
    required String status,
    required DateTime expiryDate,
    required String docType,
  }) =>
      _db.saveDocInFirebase(
        userid: userid,
        fileURL: fileURL,
        status: status,
        expiryDate: Timestamp.fromDate(expiryDate),
        docType: docType,
      );

  //obtener el documento del usuario
  Future<UserDocument?> getDoc(String userid) => _db.getDocFromFirebase(userid);

// 2:56:33
  final RutaDatabaseService _rutaService = RutaDatabaseService();

  Stream<List<Ruta>> getRutasSugeridas() {
    return _rutaService.getRutasSugeridas();
  }
}
