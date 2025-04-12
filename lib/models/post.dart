/*
  Post Model
  
*/

import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id; //id de la publicacion
  final String uid; //id del usuario que publico
  final String name; //nombre del usuario que publico
  final String username; //username del usuario que publico
  final String message; //mensaje de la publicacion
  final Timestamp timestamp; //fecha de la publicacion
  final int likeCount; //cantidad de likes
  final List<String> likedBy; //lista de IDs de quienes dieron like
  //final int commentCount; //cantidad de comentarios

  Post({
    required this.id,
    required this.uid,
    required this.name,
    required this.username,
    required this.message,
    required this.timestamp,
    required this.likeCount,
    required this.likedBy,
    //required this.commentCount,
  });

  //Convierte un documento de Firestore en un objeto de publicación (para usar en la aplicación)
  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      id: doc.id,
      uid: doc['uid'],
      name: doc['name'],
      username: doc['username'],
      message: doc['message'],
      timestamp: doc['timestamp'],
      likeCount: doc['likeCount'],
      likedBy: List<String>.from(doc['likedBy'] ?? []),
      //commentCount: doc['commentCount'],
    );
  } 
  
  //Convierte un objeto de publicación en un map (para almacenar en Firebase)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'message': message,
      'timestamp': timestamp,
      'likeCount': likeCount,
      'likedBy': likedBy,
      //'commentCount': commentCount,
    };
  }
}
