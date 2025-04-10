import 'package:firebase_auth/firebase_auth.dart';
import 'package:nau/services/auth/database/database_service.dart';
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

  //obtiene el usuario actual y el uid
  User? getCurrentUser() => _auth.currentUser;
  String getCurrentUid() => _auth.currentUser!.uid;
  //login - correo y contraseña
  Future<UserCredential>loginEmailPassword(String email, password) async {
    //intentar meterse
    try{
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
        );
      return userCredential;
    }
  //cachar errores
    on FirebaseAuthException catch(e){
      throw Exception(e.message);
    }
  }

  //registro - correo y contraseña
  Future<UserCredential>registerEmailPassword(String email, password) async {
    //intentar registrarse
    try{
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
        );
      return userCredential;
    }
    on FirebaseAuthException catch(e){
      throw Exception(e.message);
    }
  } 
  //logout
  Future<void>logout() async {
    await _auth.signOut();
  }
  //eliminar cuenta
  Future<void>deleteAccount() async {
    //obtener usuario actual
    User? user = _auth.currentUser;

    //eliminar el registro de auth del usuario
    if (user != null) {
          //eliminar datos del usuario de firestore
    await DatabaseService().deleteUserInfoFromFirebase(user.uid);
    //eliminar el registro de auth del usuario
      await user.delete();
    }
  }
}