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
*/

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String username;
  final String bio;
  final String profilePic;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.username,
    required this.bio,
    required this.profilePic,
  });
  /*firebase -> app
  convertir a documento de firestore en el perfil de usuario (para poder usarlo despues)
  */
  
   factory UserProfile.fromDocument(DocumentSnapshot doc) {
    return UserProfile(
      uid: doc['uid'],
      name: doc['name'],
      email: doc['email'],
      username: doc['username'],
      bio: doc['bio'],
      profilePic: doc['profilePic'],
    );
  }
  /*
  app -> firebase
  convertir un perfil de usuario en un mapa (para poder almacenarlo en firebase)

  */
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'username': username,
      'bio': bio,
      'profilePic': profilePic,
    };
  }
}