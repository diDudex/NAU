/*
  Datos del usuario
  aqui se guardara todo lo que el usuario deberia de tener en su perfil
  ------------------------------------------------------------------------------------------------------------
    -uid
    -nombre
    -correo
    -username
    -biografia
    -foto de perfil
    -numero de telefono
    -fecha de nacimiento
  ------------------------------------------------------------------------------------------------------------
*/

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String lastName;
  final String email;
  final String username;
  final String profilePic;
    final String phoneNumber;
  final Timestamp birthDate;

  UserProfile({
    required this.uid,
    required this.name,
    required this.lastName,
    required this.email,
    required this.username,
    required this.profilePic,
    required this.phoneNumber,
    required this.birthDate,
  });
  /*firebase -> app
  convertir a documento de firestore en el perfil de usuario (para poder usarlo despues)
  */

  // De Firestore a app
  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    return UserProfile(
      uid: doc['uid'] ?? '',
      name: doc['name'] ?? '',
      lastName: doc['lastName'] ?? '',
      email: doc['email'] ?? '',
      username: doc['username'] ?? '',
      profilePic: doc['profilePic'] ?? '',
      phoneNumber: doc['phoneNumber'] ?? '',
      birthDate: doc['birthDate'] is Timestamp ? doc['birthDate'] as Timestamp : Timestamp.now(),
    );
  }

  /*
  app -> firebase
  convertir un perfil de usuario en un mapa (para poder almacenarlo en firebase)
AIzaSyDBWSYFUP0wJK8McN03WVAzB_2yNH6JfQQ
  */
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'lastName': lastName,
      'email': email,
      'username': username,
      'profilePic': profilePic,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate,
    };
  }

  data() {}
}
