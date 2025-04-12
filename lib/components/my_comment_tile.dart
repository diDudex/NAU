import 'package:flutter/material.dart';
import 'package:nau/models/comments.dart';
import 'package:provider/provider.dart';

import '../services/auth/auth_services.dart';
import '../services/auth/database/database_provider.dart';
/*
  Comment tile
    Este es el widget de  comentarios que va debajo de una publicación
    Es pacerido al widget de publicaciones 
    pero los comentarios se ven diferentes a las publicaciones
      -----------------------------------------------------------------------------------------------
      nomas se necesita:
      - el comentario
      - una funcion para cuando le demos un click al nombre del usuario para ver el perfil
*/
class MyCommentTile extends StatelessWidget { 
  final Comment comment;
  final void Function()? onUserTap;
  const MyCommentTile({
    super.key,
    required this.comment,
    required this.onUserTap,
    });

    //mostrar opciones
  void _showOptions(BuildContext context) {
    //comprobar si el usuario es el dueño del coment
    String currentUid = AuthService().getCurrentUid();
    final bool isOwnComment = comment.uid == currentUid;

    //mostrar opciones
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              //el usuario es dueño de este comentrario?
              if (isOwnComment)

                //eliminar
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Eliminar'),
                  onTap: () async {
                    //pop option box
                    Navigator.of(context);
                    //accion de eliminar comentario
                    await Provider.of<DatabaseProvider>(context, listen: false).deleteComment(comment.id, comment.postId); 
                  },
                )
              //si el usuario no es dueño del commentario
              else ...[
                //boton de reportar
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('Reportar'),
                  onTap: () {
                    //pop option box
                    Navigator.of(context);
                    //accion de reportar
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

  @override
  Widget build(BuildContext context) {
    return Container(
        //relleno de afuera
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        //relleno de adentro
        padding: const EdgeInsets.all(10.0),

        //decoration
        decoration: BoxDecoration(
          //color
          color: Theme.of(context).colorScheme.tertiary,
          //bordes redondeados
          borderRadius: BorderRadius.circular(10.0),
        ),
        //column
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //parte de arriba
            GestureDetector(
              onTap: onUserTap,
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
                    comment.name,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 5),
                  //username
                  Text('@${comment.username}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      )),
                  const Spacer(),
                  //Boton -> mas opciones: eliminar
                  GestureDetector(
                      onTap: () => _showOptions(context),
                      child: Icon(Icons.more_horiz,
                          color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            //post
            Text(
              comment.message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 15),
/*            Row(
              children: [
                //seccion de likes
                SizedBox(
                  width: 40,
                  child: Row(
                    children: [
                      //likes
                      GestureDetector(
                          onTap: _toggleLikeComment,
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
              ],
            )*/
          ],
        ),
      );
  }
}