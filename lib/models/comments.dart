import 'package:cloud_firestore/cloud_firestore.dart';
/*
 Modelo de comentarios
  -----------------------------------------------------------------------------------------------
  este modelo se usara para almacenar los comentarios de los usuarios en la base de datos
*/

class Comment {
  final String id; //id del comentario
  final String postId; //id de la publicacion
  final String uid; //id del usuario
  final String name; //nombre del usuario
  final String username; //username de usuario
  final String message; //mensaje del comentario
  final Timestamp timestamp; //fecha y hora del comentario
  final int likeCount; //cantidad de likes

  Comment({
    required this.id,
    required this.postId,
    required this.uid,
    required this.name,
    required this.username,
    required this.message,
    required this.timestamp,
    required this.likeCount,
  });  
  //convertir el documento de firestore en un comentario
  factory Comment.fromDocument(DocumentSnapshot doc){
    return Comment(
      id: doc.id,
      postId: doc['postId'],
      uid: doc['uid'],
      name: doc['name'],
      username: doc['username'],
      message: doc['message'],
      timestamp: doc['timestamp'],
      likeCount: doc['likeCount'],
    );
  } 
  //convertir el comentario en un mapa para poder almacenarlo en firebase
  Map<String, dynamic> toMap(){
    return {
      'postId': postId,
      'uid': uid,
      'name': name,
      'username': username,
      'message': message,
      'timestamp': timestamp,
      'likeCount': likeCount,
    };
  }
}