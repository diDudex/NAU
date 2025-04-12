import 'package:flutter/material.dart';
import 'package:nau/components/my_input_alert_box.dart';
import 'package:nau/components/my_post_tile.dart';
import 'package:nau/helper/navigate_pages.dart';
import 'package:nau/models/post.dart';
import 'package:nau/services/auth/database/database_provider.dart';
import 'package:provider/provider.dart';
import '../components/my_drawer.dart';

/*
  HOME PAGE
    Esta es la página de inicio de la aplicación: muestra las publicaciones de los usuarios
    -----------------------------------------------------------------------------------------------
*/
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //providers
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider =
      Provider.of<DatabaseProvider>(context, listen: false);

  //Text controller para la publicacion
  final _messageController = TextEditingController();

  //al iniciar
  @override
  void initState() {
    super.initState();
    //vamos a cargar todas las publicaciones
    loadAllPosts();
  }

  Future<void> loadAllPosts() async {
    //obtener todas las publicaciones
    await databaseProvider.loadAllPosts();
  }

  //mostrar box de publicacion
  void _openPostMessageBox() {
    showDialog(
      context: context,
      builder: (context) => MyInputAlertBox(
          textController: _messageController,
          hintText: "En que estas pensando?...",
          onPressed: () async {
            //post en la db
            await _postMessage(_messageController.text);
          },
          onPressedText: "Publicar"),
    );
  }

  //si el usuario quiere hacer una publicacion
  Future<void> _postMessage(String message) async {
    //post message en firebase
    await databaseProvider.postMessage(message);
  }

  //Construccion de la interfaz de usuario
  @override
  Widget build(BuildContext context) {
    //scaffold
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: MyDrawer(),
      //appbar
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Inicio"),
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      //boton flotante
      floatingActionButton: FloatingActionButton(
        onPressed: _openPostMessageBox,
        child: const Icon(Icons.add),
      ),
      //Body lista de todos los posts
      body: _buildPostList(listeningProvider.allPosts),
    );
  }

  //construccion de la lista de publicaciones
  Widget _buildPostList(List<Post> posts) {
    return posts.isEmpty
        ?
        //lista de publicaciones vacia
        const Center(child: Text("No hay publicaciones..."))
        :
        //so la lista de publicaciones no esta vacia
        ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              //obtiene cada post individual
              final post = posts[index];
              //construye la tarjeta de publicacion //card
              return MyPostTile(
                post: post, 
                onUserTap: () => goUserPage(context, post.uid),
                onPostTap: () => goPostPage(context, post),  
              );
            },
          );
  }
}
