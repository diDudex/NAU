import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nau/models/post.dart';
import 'package:nau/models/user.dart';
import 'package:nau/services/auth/auth_services.dart';

import '../../../models/comments.dart';

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
  Future<void> saveUserInfoInFirebase(
      {required String name, required String email}) async {
    //obtener el uid del usuario actual
    final uid = _auth.currentUser!.uid;
    //extraer el username desde el correo (ejemplo -> usu@gmail.com -> username: usu)
    final username = email.split('@')[0];
    //crear  perfil de usuario
    UserProfile user = UserProfile(
        uid: uid,
        name: name,
        email: email,
        username: username,
        bio: '',
        profilePic: '');
    //convertir el perfil de usuario en un mapa para poder almacenarlo en firebase
    final userMap = user.toMap();
    //almacenar la informacion del usuario en firebase
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

  //Actualizar la biografia del usuario
  Future<void> updateUserBioInFirebase(String bio) async {
    //obtener el uid del usuario actual
    String uid = AuthService().getCurrentUid();

    //intentar actualuizar la biografia del usuario en la base de datos
    try {
      await _db.collection('Users').doc(uid).update({'bio': bio});
    } catch (e) {
      print(e);
    }
  }

/*
  Publicaciones
*/
  //Mensaje de post
  Future<void> postMessageInFirebase(String message) async {
    // intentar publicar el mensaje en firebase
    try {
      //obtener el uid del usuario actual
      String uid = _auth.currentUser!.uid;

      //usar esto para obtener el uid del usuario actual
      UserProfile? user = await getUserFromFirebase(uid);

      //crear una nueva publicacion
      Post newPost = Post(
        id: '', //firebase lo genera automaticamente
        uid: uid,
        name: user!.name,
        username: user.username,
        message: message,
        timestamp: Timestamp.now(),
        likeCount: 0,
        likedBy: [],
      );
      //convertir la publicacion en un mapa para poder almacenarla en firebase
      Map<String, dynamic> newPostMap = newPost.toMap();
      //almacenar la publicacion en firebase
      await _db.collection('Posts').add(newPostMap);
    }
    //cachar cualquier error
    catch (e) {
      print(e);
    }
  }

  //Eliminar post
  Future<void> deletePostFromFirebase(String postId) async {
    //intentar eliminar la publicacion de firebase
    try {
      //eliminar la publicacion de firebase
      await _db.collection('Posts').doc(postId).delete();
    }
    //cachar cualquier error
    catch (e) {
      print(e);
    }
  }

  //Obtener  todos los post
  Future<List<Post>> getAllPostsFromFirebase() async {
    //intentar obtener todas las publicaciones de firebase
    try {
      //obtener todas las publicaciones de firebase
      QuerySnapshot snapshot = await _db
          //va a la coleccion de Posts
          .collection('Posts')
          //ordena de manera cronologica los posts (el mas reciente primero)
          .orderBy('timestamp', descending: true)
          //obtiene los documentos
          .get();
      //regresa una lista de publicaciones
      return snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    }
    //cachar cualquier error
    catch (e) {
      print(e);
      return [];
    }
  }

  //eliminar informacion de usuario
  Future<void> deleteUserInfoFromFirebase(String uid) async {
    WriteBatch batch = _db.batch();

    //eliminar user doc
    DocumentReference userDoc = _db.collection('Users').doc(uid);
    batch.delete(userDoc);
    //eliminar user posts
    QuerySnapshot userPosts = await _db
        .collection('Posts')
        .where('uid', isEqualTo: uid)
        .get();
    for (var post in userPosts.docs) {
      batch.delete(post.reference);
    }
    //eliminar user comments
    QuerySnapshot userComments = await _db
        .collection('Comments')
        .where('uid', isEqualTo: uid)
        .get();
    for (var comment in userComments.docs) {
      batch.delete(comment.reference);
    }
    //eliminar los likes del usuario 3:19:00
    QuerySnapshot allPosts = await _db.collection('Posts').get();
    for (QueryDocumentSnapshot post in allPosts.docs) {
      Map <String, dynamic> postData = post.data() as Map<String, dynamic>;
      var likedBy = postData['likedBy'] as List <dynamic>? ?? [];

      if (likedBy.contains(uid)) {
        batch.update(post.reference, {
          'likedBy': FieldValue.arrayRemove([uid]),
          'likeCount': FieldValue.increment(-1),
          }
        );
      }
    }
    //Actualizar seguidores y registros de seguimiento según corresponda

    //commit batch
    await batch.commit();
  }
/*
  Likes
*/
  //dar like a una publicacion
  Future<void> toggleLikeInFirebase(String postId) async {
    //obtener el uid del usuario actual
    String uid = _auth.currentUser!.uid;
    //intentar dar like a la publicacion
    try {
      //ir al documento del post
      DocumentReference postDoc = _db.collection("Posts").doc(postId);
      //ejecutar el like
      await _db.runTransaction((transaction) async {
        //obtener el post
        DocumentSnapshot postSnapshot = await transaction.get(postDoc);
        List<String> likedBy = List<String>.from(postSnapshot['likedBy'] ?? []);
        //obtener el contador de likes
        int currentLikeCount = postSnapshot['likeCount'];

        //si el usuario no ha dado like, entonces dar like
        if (!likedBy.contains(uid)) {
          likedBy.add(uid);
          currentLikeCount++;
        }
        //si el usuario ya dio like, entonces quitar el like
        else {
          likedBy.remove(uid);
          currentLikeCount--;
        }
        //actualizar los likes y los usuarios que dieron like
        transaction.update(
            postDoc, {'likeCount': currentLikeCount, 'likedBy': likedBy});
      });
    } //2:18:45
    //cachar cualquier error
    catch (e) {
      print(e);
    }
  }

/*
  Comentarios 2:35:00
*/
  //agregar comentario al post
  Future<void> addCommentInFirebase(String postId, String message) async {
    try {
      //obtener el uid del usuario actual
      String uid = _auth.currentUser!.uid;
      //usar esto para obtener el uid del usuario actual
      UserProfile? user = await getUserFromFirebase(uid);

      //crear un nuevo comentario
      Comment newComment = Comment(
        id: '', //firebase lo genera automaticamente
        postId: postId,
        uid: uid,
        name: user!.name,
        username: user.username,
        message: message,
        timestamp: Timestamp.now(),
        likeCount: 0,
      );
      //convertir el comentario en un mapa para poder almacenarlo en firebase
      Map<String, dynamic> newCommentMap = newComment.toMap();
      //almacenar el comentario en firebase
      await _db.collection('Comments').add(newCommentMap);
    }
    //cachar cualquier error
    catch (e) {
      print(e);
    }
  }

  //eliminar comentario del post
  Future<void> deleteCommentInFirebase(String commentId) async {
    //intentar eliminar el comentario de firebase
    try {
      //eliminar el comentario de firebase
      await _db.collection('Comments').doc(commentId).delete();
    }
    //cachar cualquier error
    catch (e) {
      print(e);
    }
  }

  //obtener comentarios del post
  Future<List<Comment>> getCommentsFromFirebase(String postId) async {
    try {
      //obtener todos los comentarios del post
      QuerySnapshot snapshot = await _db
          //va a la coleccion de Comments
          .collection('Comments')
          .where("postId", isEqualTo: postId)
          .get();
      //regresa una lista de comentarios
      return snapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();
    }
    //cachar cualquier error
    catch (e) {
      print(e);
      return [];
    }
  } //2:44:55
/*
  Seguidores/seguidos
*/

/*
  Usuarios buscados
*/

/*
  Cosas y ajustes de la cuenta // 2:54:23
  requisitos para publicar en las appstores 
*/
  //report post
  Future<void> reportUserInFirebase(String postId, userId) async {
    //obtener el uid del usuario actual
    final currentUserId = _auth.currentUser!.uid;
    //crear un mapa de reporte
    final report = {
      'reporterId': currentUserId,
      'messageId': postId,
      'messageOwnerId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    };
    //actualizar el reporte en firebase
    await _db.collection('Reports').add(report);
  }

  //bloquear usuario
  Future<void> blockUserInFirebase(String userId) async {
    //obtener el uid del usuario actual
    final currentUserId = _auth.currentUser!.uid;
    // añadir el usuario a la lista de bloqueados
    await _db
        .collection('Users')
        .doc(currentUserId)
        .collection("BlockedUsers")
        .doc(userId)
        .set({});
  }
  
  //desbloquear usuario
  Future<void> unblockUserInFirebase(String blockedUserId) async {
    //obtener el uid del usuario actual
    final currentUserId = _auth.currentUser!.uid;
    // eliminar el usuario de la lista de bloqueados
    await _db
        .collection('Users')
        .doc(currentUserId)
        .collection("BlockedUsers")
        .doc(blockedUserId)
        .delete();
  }
  
  //Obtener lista de ids de usuarios bloqueados
  Future<List<String>> getBlockedUidsFromFirebase() async {
    //obtener el uid del usuario actual
    final currentUserId = _auth.currentUser!.uid;
    //obtener la lista de usuarios bloqueados
    final snapshot = await _db
        .collection('Users')
        .doc(currentUserId)
        .collection("BlockedUsers")
        .get();
    //regresar una lista de ids de usuarios bloqueados
    return snapshot.docs.map((doc) => doc.id).toList();
  }
  //eliminar cuenta
}
