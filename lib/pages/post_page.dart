import 'package:flutter/material.dart';
import 'package:nau/components/my_comment_tile.dart';
import 'package:nau/components/my_post_tile.dart';
import 'package:nau/helper/navigate_pages.dart';
import 'package:nau/models/post.dart';
import 'package:provider/provider.dart';

import '../services/auth/database/database_provider.dart';
/*
   Post Page
    Esta pantalla mostrara:
    - post individual
    - comentarios del post
*/

class PostPage extends StatefulWidget {
  final Post post;

  const PostPage({
    super.key,
    required this.post,
  });

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider =
      Provider.of<DatabaseProvider>(context, listen: false);


  //Construccion de la UI
  @override
  Widget build(BuildContext context) {
    //listen a todos los commentarios del post
    final allComments = listeningProvider.getComments(widget.post.id);
    //Scaffold
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        //AppBar
        appBar: AppBar(
          foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        //Body
        body: ListView(children: [
          //Post
          MyPostTile(
              post: widget.post, 
              onUserTap: ()=> goUserPage(context, widget.post.uid), 
              onPostTap: (){},),

          //Comentarios
        allComments.isEmpty
            ? const Center(
                child: Text("No hay comentarios"),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allComments.length,
                itemBuilder: (context, index) {
                  final comment = allComments[index];
                  return  MyCommentTile(
                    comment: comment,
                    onUserTap: ()=> goUserPage(context, comment.uid),
                  );
                },
              )
      ])
    );
  }
}
