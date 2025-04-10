import 'package:flutter/material.dart';
import 'package:nau/components/my_input_alert_box.dart';
import 'package:nau/models/post.dart';
import 'package:nau/services/auth/auth_services.dart';
import 'package:provider/provider.dart';

import '../services/auth/database/database_provider.dart';
/*
  Post marco
  todos los post se mostraran usando este widget
  -----------------------------------------------------------------------------------------------
  nomas se necestita:
  - el post
  - una funcion para cuando le demos un click vaya de manera individual al post para ver los commentarios
  - una funcion para cuando le demos un click al nombre del usuari para ver el perfil
*/

class MyPostTile extends StatefulWidget {
  final Post post;
  final void Function()? onUserTap;
  final void Function()? onPostTap;

  const MyPostTile({
    super.key,
    required this.post,
    required this.onUserTap,
    required this.onPostTap,
  });

  @override
  State<MyPostTile> createState() => _MyPostTileState();
}

class _MyPostTileState extends State<MyPostTile> {
  //providers
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider =
      Provider.of<DatabaseProvider>(context, listen: false);

    //al iniciar
  @override
  void initState() {
    super.initState();
    //cargar comentarios
    _loadComments();
  }
  /*

    Likes

  */
  //el usuario dio like o no
  void _toggleLikePost() async {
    try {
      await databaseProvider.toggleLike(widget.post.id);
    } catch (e) {
      print(e);
    }
  }


  /*

    Comentarios
  
  */
    void _toggleLikeComment() async {
    try {
      await databaseProvider.toggleLike(widget.post.id);
    } catch (e) {
      print(e);
    }
  }
  //comment text cotnroller
  final _commentController = TextEditingController();
  //abrir caja de comentarios
  void _openNewCommentBox(){
    showDialog(context: context, builder: (context) => MyInputAlertBox(
      textController: _commentController, 
      hintText: "Escribe un comentario...", 
      onPressed: ()async{
        //agregar comentario
        await _addComment();
        //limpiar el campo de texto
        _commentController.clear();
      }, 
      onPressedText: "Comentar"
      ),
    );
  }
  //agregar comentario
  Future<void> _addComment() async{
    try {
      //agregar comentario
      await databaseProvider.addComment(widget.post.id, _commentController.text.trim());
    } catch (e) {
      print(e);
    }
  }
  //cargar comentarios
  Future<void> _loadComments() async{
   
      //cargar comentarios
      await databaseProvider.loadComments(widget.post.id);

  }
  /*
  Mostrar opciones

  Caso 1: esta publicación pertenece al usuario actual
  - Eliminar
  - cancelar
  Caso : esta publicación no pertenece al usuario actual
  - Reportar
  - Bloquear usuario
  - cancelar
  */

  //mostrar opciones
  void _showOptions() {
    //comprobar si el usuario es el dueño del post
    String currentUid = AuthService().getCurrentUid();
    final bool isOwnPost = widget.post.uid == currentUid;

    //mostrar opciones
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              //el usuario es dueño de este post?
              if (isOwnPost)

                //eliminar
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Eliminar'),
                  onTap: () async {
                    //pop option box
                    Navigator.of(context);
                    //accion de eliminar post
                    await databaseProvider.deletePost(widget.post.id);
                  },
                )
              //si el usuario no es dueño del post
              else ...[
                //boton de reportar
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('Reportar'),
                  onTap: () async{
                    //pop option box
                    Navigator.pop(context);
                    //accion de reportar
                    _reportPostConfirmationBox();
                  },
                ),
                //bloquear usuario
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Bloquear usuario'),
                  onTap: () {
                    //pop option box
                    Navigator.of(context);
                    //accion de bloquear
                    _blockConfirmationBox();
                  },
                )
              ],
              //cancelar
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancelar'),
                onTap: () => Navigator.of(context),
              )
            ],
          ),
        );
      },
    );
  }
    //reportar post confirmation box
  void _reportPostConfirmationBox() {
    //mostrar dialogo de confirmacion
    showDialog(
      context: context,
      builder: (context) => 
         AlertDialog(
          title: const Text('Reportar publicación'),
          content: const Text(
              '¿Estás seguro de que quieres reportar esta publicación?'),
          actions: [
            //cancelar
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            //reportar
            TextButton(
              onPressed: () async {
                //reportar post
                await databaseProvider.reportUser(widget.post.id, widget.post.uid);
                //pop dialog
                Navigator.of(context).pop();
                //Dejar que el usuario sepa que fue exitoso
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Publicación reportada'),
                  ),
                );
              },
              child: const Text('Reportar'),
            ),
          ],
        ),
    );
  }
  //blockl userconfirmation box
  void _blockConfirmationBox() {
    //mostrar dialogo de confirmacion
    showDialog(
      context: context,
      builder: (context) => 
         AlertDialog(
          title: const Text('Bloquear usuario'),
          content: const Text(
              '¿Estás seguro de que quieres bloquear a este usuario?'),
          actions: [
            //cancelar
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            //bloquear
            TextButton(
              onPressed: () async {
                //block user
                await databaseProvider.blockUser(widget.post.uid,);
                //pop dialog
                Navigator.pop(context);
                //Dejar que el usuario sepa que fue exitoso
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario bloqueado'),
                  ),
                );
              },
              child: const Text('Bloquear'),
            ),
          ],
        ),
    );
  }
  //Construccion de la UI
  @override
  Widget build(BuildContext context) {
    //al usuario le gusta este post?
    bool likedByCurrentUser =
        listeningProvider.isPostLikedByCurrentUser(widget.post.id);
    //listen para like count
    int likeCount = listeningProvider.getLikeCount(widget.post.id);
    //listen para comment count
    int commentCount = listeningProvider.getComments(widget.post.id).length;
    //int likeCommentCount = listeningProvider.getLikeCommentCount(widget.post.id);
    //Container
    return GestureDetector(
      onTap: widget.onPostTap,
      child: Container(
        //relleno de afuera
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        //relleno de adentro
        padding: const EdgeInsets.all(10.0),

        //decoration
        decoration: BoxDecoration(
          //color
          color: Theme.of(context).colorScheme.secondary,
          //bordes redondeados
          borderRadius: BorderRadius.circular(10.0),
        ),
        //column
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //parte de arriba
            GestureDetector(
              onTap: widget.onUserTap,
              child: Row(
                children: [
                  //foto de perfil
                  Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 5),
                  //name
                  Text(
                    widget.post.name,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 5),
                  //username
                  Text('@${widget.post.username}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      )),
                  const Spacer(),
                  //Boton -> mas opciones: eliminar
                  GestureDetector(
                      onTap: _showOptions,
                      child: Icon(Icons.more_horiz,
                          color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            //post
            Text(
              widget.post.message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                //seccion de likes
                SizedBox(
                  width: 40,
                  child: Row(
                    children: [
                      //likes
                      GestureDetector(
                          onTap: _toggleLikePost,
                          child: likedByCurrentUser
                              ? const Icon(Icons.favorite, color: Colors.red)
                              : Icon(
                                  Icons.favorite_border,
                                  color: Theme.of(context).colorScheme.primary,
                                )),
                      const SizedBox(width: 5),
                      //like count
                      Text(
                        likeCount != 0 ? likeCount.toString() : '',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    //comentarios
                    GestureDetector(
                        onTap: _openNewCommentBox,
                        child: Icon(
                          Icons.comment,
                          color: Theme.of(context).colorScheme.primary,
                        )),
                    const SizedBox(width: 5),
                    //comentarios count
                    Text( commentCount != 0 ? commentCount.toString() : '',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
