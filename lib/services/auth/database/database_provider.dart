import 'package:flutter/material.dart';
import 'package:nau/models/comments.dart';
import 'package:nau/models/post.dart';
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
  final _auth = AuthService();
  /*
  Perfil de usuario

  */

  //obtener el perfil del usuario actual por su uid
  Future<UserProfile?> userProfile(String uid) => _db.getUserFromFirebase(uid);

  //actualizar la biografía del usuario
  Future<void> updateBio(String bio) => _db.updateUserBioInFirebase(bio);

  /*
  Posts
  */
  //Lista local de publicaciones
  List<Post> _allPosts = [];
  //obtener publicaciones
  List<Post> get allPosts => _allPosts;
  //post message
  Future<void> postMessage(String message) async {
    //post message en firebase
    await _db.postMessageInFirebase(message);

    //recargar todas las publicaciones
    await loadAllPosts(); //fetch all posts
  }

  //recuperar todas las publicaciones //loadAllPosts() {}
  Future<void> loadAllPosts() async {

    //obtener todas las publicaciones
    final allPosts = await _db.getAllPostsFromFirebase();
    //obtener ids de usuarios bloqueados
    final blockedUsersIds = await _db.getBlockedUidsFromFirebase();
    //filtrar publicaciones de usuarios bloqueados y actualizar la lista de publicaciones
    _allPosts = allPosts.where((post) => !blockedUsersIds.contains(post.uid)).toList();

    //iniciar datos locales de likes
    initializeLikeMap();
    //notificar a los listeners
    notifyListeners();
  }

  //filtrar y recuperar publicaciones de un usuario en particular
  List<Post> filterUserPosts(String uid) {
    return _allPosts.where((post) => post.uid == uid).toList();
  }

  //eliminar publicacion
  Future<void> deletePost(String postId) async {
    //eliminar la publicacion de firebase
    await _db.deletePostFromFirebase(postId);
    //recargar todas las publicaciones
    await loadAllPosts();
  }

  /*
  Likes
  */
  //map local para realizar seguimiento del recuento de cada post
  Map<String, int> _likeCounts = {
    //cada post tiene un recuento de likes
  };
  //lista local para realizar seguimiento de los post que le gustan al usuario actual
  List<String> _likedPosts = [];

  //al usuario actual le gusta este post?
  bool isPostLikedByCurrentUser(String postId) => _likedPosts.contains(postId);
  //obtener el recuento de likes de un post
  int getLikeCount(String postId) => _likeCounts[postId] ?? 0;
  //iniciar map como local
  void initializeLikeMap() {
    //obtener el usuario actual
    final currentUserID = _auth.getCurrentUid();
    //limpiar like de post (para cuando un usuario local diferente entre)
    _likedPosts.clear();
    //por cada post que obtenga datos similares
    for (var post in _allPosts) {
      //actualizar el map contador de likes
      _likeCounts[post.id] = post.likeCount;

      //si al usuario actual ya le gusta el post
      if (post.likedBy.contains(currentUserID)) {
        //agregar el post a la lista de post que le gustan al usuario actual
        _likedPosts.add(post.id);
      }
    }
  }

  //alternar like
  Future<void> toggleLike(String postId) async {
    /*
    Pon atencion pinche Jesus, aqui es donde se va a hacer la magia de la optimizacion de la UI

    Esta primera parte actualizará primero los valores locales para que la interfaz de usuario 
    se sienta inmediata y responsiva. Actualizaremos la interfaz de usuario de manera optimista y 
    volveremos a la versión anterior si algo sale mal mientras se escribe en la base de datos.
    
    Actualizar los valores locales de manera optimista de esta manera es importante porque: 
    leer y escribir desde la base de datos lleva algo de tiempo (1 a 2 segundos, según la conexión a Internet). 
    Por lo tanto, no queremos brindarle al usuario una experiencia lenta y con retrasos
    
    */

    //guardar el recuento de likes original si algo falla
    final likedPostsOriginal = _likedPosts;
    final likeCountsOriginal = _likeCounts;
    //accionar like/unlike
    if (_likedPosts.contains(postId)) {
      //quitar like
      _likedPosts.remove(postId);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) - 1;
    } else {
      //dar like
      _likedPosts.add(postId);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
    }
    //actualizar UI local
    notifyListeners();
    /*
    actualizar en la base de datos.
    */
    try {
      //actualizar en firebase
      await _db.toggleLikeInFirebase(postId);
    } catch (e) {
      //si algo sale mal, entonces volver a la versión anterior
      _likedPosts = likedPostsOriginal;
      _likeCounts = likeCountsOriginal;
      //actualizar UI local
      notifyListeners();
      //imprimir error
      print(e);
    }
  }

/*
  Comentarios

  {
  posrId1: [comment1, comment2, ...],
  posrId2: [comment1, comment2,...],
  posrId3: [comment1, comment2,...],
  
  }
*/
  //lista local de comentarios
  final Map<String, List<Comment>> _comments = {};

  //obtener comentarios de un post
  List<Comment> getComments(String postId) => _comments[postId] ?? [];

  //obtener commentarios de una publicacion desde la BD
  Future<void> loadComments(String postId) async {
    //obtener comentarios de firebase
    final allComments = await _db.getCommentsFromFirebase(postId);
    //actualizar comentarios locales
    _comments[postId] = allComments;
    //actualizar UI
    notifyListeners();
  }

  //añadir comentario
  Future<void> addComment(String postId, String message) async {
    //añadir comentario a firebase
    await _db.addCommentInFirebase(postId, message);
    //recargar comentarios
    await loadComments(postId);
  }

  //eliminar comentario
  Future<void> deleteComment(String commentId, postId) async {
    //eliminar comentario de firebase
    await _db.deleteCommentInFirebase(commentId);
    //recargar comentarios
    await loadComments(postId);
  }

  /*

  Cosas de la cuenta

  */
  //lista local de usuarios nloqueados
  List<UserProfile> _blockedUsers = [];
  //obtener lista de usuarios bloqueados
  List<UserProfile> get blockedUsers => _blockedUsers;
  //buscar usuarios nloqueados
  Future<void> loadBlockedUsers() async {
    //obtener ids de usuarios bloqueados
    final blockedUsersIds = await _db.getBlockedUidsFromFirebase();
    //obtener todos los detalles del uid del usuario
    final blockedUsersData = await Future.wait(
        blockedUsersIds.map((id) => _db.getUserFromFirebase(id)));
    //actualizar datos locales
    _blockedUsers = blockedUsersData.whereType<UserProfile>().toList();
    //notificar a los listeners
    notifyListeners();
  }
  
  //bloquear usuario
  Future<void> blockUser(String userId) async {
    //bloquear usuario en firebase
    await _db.blockUserInFirebase(userId);
    //recargar lista de usuarios bloqueados
    await loadBlockedUsers();
    //recargar todos los datos
    await loadAllPosts();
    //notificar a los listeners
    notifyListeners();
  }
  //desbloquear usuario
  Future<void> unblockUser(String blockedUserId) async {
    //desbloquear usuario en firebase
    await _db.unblockUserInFirebase(blockedUserId);
    //recargar lista de usuarios bloqueados
    await loadBlockedUsers();
    //recargar todas las publicaciones
    await loadAllPosts();
    //notificar a los listeners
    notifyListeners();
  }
  //reportar usuario y post
  Future<void> reportUser(String postId, userId) async {
    //reportar usuario y post en firebase
    await _db.reportUserInFirebase(postId, userId);
 /*   //recargar todos los datos
    await loadAllPosts();
    //notificar a los listeners
    notifyListeners(); */
  }
// 2:56:33
  final RutaDatabaseService _rutaService = RutaDatabaseService();

  Stream<List<Ruta>> getRutasSugeridas() {
    return _rutaService.getRutasSugeridas();
}
}