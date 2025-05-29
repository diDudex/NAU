import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
/*
  Servicio de autenticación
    esto servira para autenticarse con firebase
    ----------------------------------------------------------------------------------------------------------------
    -Login
    -Registro
    -Logout
    -Eliminar cuenta

*/

class AuthService {
  //obtiene la instancia de firebase
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  //obtiene el usuario actual y el uid
  User? getCurrentUser() => _auth.currentUser;
  String getCurrentUid() => _auth.currentUser!.uid;
  //login - correo y contraseña
  Future<UserCredential> loginEmailPassword(String email, password) async {
    //intentar meterse
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential;
    }
    //cachar errores
    on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  //registro - correo y contraseña
  Future<UserCredential> registerEmailPassword(String email, password) async {
    //intentar registrarse
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  //logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  //eliminar cuenta
  Future<void> deleteAccount() async {
    String uid = getCurrentUid();

    try {
      // Elimina los datos del usuario en Firestore
      await _db.collection('Users').doc(uid).delete();

      // Elimina el usuario de Firebase Authentication
      User? user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }

      // Cierra la sesión después de eliminar la cuenta
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error al eliminar la cuenta: $e');
    }
  }
}
