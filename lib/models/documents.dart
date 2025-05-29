/*
  Datos de lo documentos del usuario
  ------------------------------------------------------------------------------------------------------------
  aqui se guardara todo lo que el usuario deberia de tener en su perfil
  ------------------------------------------------------------------------------------------------------------
    -userid
    -fileURL
    -status(pendiente, activo, rechazado, sin documentos)
    -expiryDate
    -docType
  ------------------------------------------------------------------------------------------------------------
*/

import 'package:cloud_firestore/cloud_firestore.dart';

class UserDocument {
  final String userid;
  final String fileURL;
  final String status; // pendiente, activo, rechazado, sin documentos
  final Timestamp expiryDate; // Fecha de expiración (puede ser null)
  final String docType; // Tipo de documento (Estudiante, Jubilado/Pensionado, Discapacidad,Otro)

  UserDocument({
    required this.userid,
    required this.fileURL,
    required this.status,
    required this.expiryDate,
    required this.docType,
  });

  /// Convierte un documento de Firestore a una instancia de UserDocument
  factory UserDocument.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Documento vacío o nulo');
    }

    return UserDocument(
      userid: data['userid'] ?? '',
      fileURL: data['fileURL'] ?? '',
      status: data['status'] ?? 'sin documentos',
      expiryDate: data['expiryDate'] != null ? data['expiryDate'] as Timestamp : Timestamp(0, 0),
      docType: data['docType'] ?? '', 
    );
  }

  /// Convierte la instancia a un mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'userid': userid,
      'fileURL': fileURL,
      'status': status,
      'expiryDate': expiryDate,
      'docType': docType,
    };
  }

  /// Crea un documento vacío (sin documentos)
  factory UserDocument.empty(String uid) {
    return UserDocument(
      userid: uid,
      fileURL: '',
      status: 'sin documentos',
      expiryDate: Timestamp(0, 0),
      docType: '',
    );
  }
}
