import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nau/models/user.dart';
import 'package:nau/services/auth/auth_services.dart';

import '../../../models/documents.dart';

/*
  Servicios de la base de datos
    Esta clase maneja todos los datos desde y hacia Firebase.
    --------------------------------------------------------------------------------
    -User profile
    - Publicaciones (post)
    - Likes
    - Comentarios
    - Seguidores/seguidos
    - Usuarios buscados
    - Cosas de la cuenta (reportes/bloqueos/cuenta/eliminar cuenta)
*/
class DatabaseService {
//obtiene la instancia de firestore db y auth
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

/*
  Perfil de usuario
  Cuando un nuevo usuario se registra, se crea una cuenta para él, pero también almacenamos sus 
  detalles en la base de datos para mostrarlos en su página de perfil.
  -----------------------------------------------------------------------------------------------

*/

  //Guardar informacion del usuario
  Future<void> saveUserInfoInFirebase({
    required String name,
    required String email,
    required String lastName,
    required String phoneNumber,
    required Timestamp birthDate,
  }) async {
    // Obtener uid del usuario actual
    final uid = _auth.currentUser!.uid;

    // Extraer username desde el correo
    final username = email.split('@')[0];

    // Crear perfil de usuario con todos los datos
    UserProfile user = UserProfile(
      uid: uid,
      name: name,
      lastName: lastName,
      email: email,
      username: username,
      profilePic: '',
      phoneNumber: phoneNumber,
      birthDate: birthDate,
    );

    // Convertir el perfil a mapa para guardar en Firestore
    final userMap = user.toMap();

    // Guardar la información en Firestore
    await _db.collection('Users').doc(uid).set(userMap);
  }

  //Obtener informacion del usuario
  Future<UserProfile?> getUserFromFirebase(String uid) async {
    try {
      //recuperar la informacion del usuario desde firebase
      DocumentSnapshot userDoc = await _db.collection('Users').doc(uid).get();
      //convertir el documento de firestore en el perfil de usuario
      return UserProfile.fromDocument(userDoc);
    } catch (e) {
      print(e);
      return null;
    }
  }

  //Obtener documentos del usuario
  Future<UserDocument?> getDocFromFirebase(String uid) async {
    try {
      DocumentSnapshot docUser =
          await _db.collection('Documents').doc(uid).get();

      if (!docUser.exists || docUser.data() == null) {
        // No existe documento, retornamos null o un objeto con status 'sin documentos'
        return UserDocument(
          userid: uid,
          fileURL: '',
          status: 'sin documentos', // Indica que no hay documentos aún
          expiryDate: Timestamp(0, 0),
          docType: '',
        );
      }

      // Si existe el documento, convertirlo normalmente
      return UserDocument.fromDocument(docUser);
    } catch (e) {
      print('Error obteniendo documento: $e');
      return null;
    }
  }

  //Guardar los documentos del usuario
  Future<void> saveDocInFirebase({
    required String userid,
    required String fileURL,
    required String status,
    required Timestamp expiryDate,
    required String docType,
  }) async {
    // Obtener uid del usuario actual
    final uid = _auth.currentUser!.uid;

    // Crear perfil de documentos con todos los datos
    UserDocument user = UserDocument(
      userid: userid,
      fileURL: fileURL,
      status: status,
      expiryDate: expiryDate,
      docType: docType,
    );

    // Convertir el perfil a mapa para guardar en Firestore
    final userMap = user.toMap();

    // Guardar la información en Firestore
    await _db.collection('Documents').doc(uid).set(userMap);
  }

  userProfile(String userId) {}

}
