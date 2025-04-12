import 'package:flutter/material.dart';
import 'package:nau/components/my_bio_box.dart';
import 'package:nau/components/my_post_tile.dart';
import 'package:nau/models/user.dart';
import 'package:nau/services/auth/auth_services.dart';
import 'package:nau/services/auth/database/database_provider.dart';
import 'package:provider/provider.dart';

import '../components/my_input_alert_box.dart';
import '../helper/navigate_pages.dart';

/*
  Pagina de perfil
    Esta es una página de perfil para un uid determinado
    -----------------------------------------------------------------------------------------------
      1:56:39
*/

class ProfilePage extends StatefulWidget {
  //user id
  final String uid;
  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  //providers
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider =
      Provider.of<DatabaseProvider>(context, listen: false);

  //user info
  UserProfile? user;
  String currentUserId = AuthService().getCurrentUid();

  //Text controller para la bio
  final bioTextController = TextEditingController();

  //loading...
  bool _isLoading = true;

  //al iniciar
  @override
  void initState() {
    super.initState();
    //cargar informacion del usuario
    loadUser();
  }

  Future<void> loadUser() async {
    //obtener informacion del usuario
    user = await databaseProvider.userProfile(widget.uid);
    //finalizar la carga
    setState(() {
      _isLoading = false;
    });
  }

  //mostrar caja de edicion de bio
  void _showEditBioBox() {
    showDialog(
        context: context,
        builder: (context) => MyInputAlertBox(
              textController: bioTextController,
              hintText: 'Bio...',
              onPressed: saveBio,
              onPressedText: 'Actualizar',
            ));
  }

  //guardar la actualizacion de la bio
  Future<void> saveBio() async {
    //iniciar la carga
    setState(() {
      _isLoading = true;
    });
    //actualizar la bio
    await databaseProvider.updateBio(bioTextController.text);

    //recargar la informacion del usuario
    await loadUser();

    //finalizar la carga
    setState(() {
      _isLoading = false;
    });

    print("Guardando...");
  }

  //build de la interfaz de usuario
  @override
  Widget build(BuildContext context) {
    //obtener posts de el usuario actual
    final allUserPosts = listeningProvider.filterUserPosts(widget.uid);
    //scaffold
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface, //color de fondo
      //appbar
      appBar: AppBar(
        title: Text(_isLoading ? '' : user!.name),
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      //Body
      body: ListView(
        children: [
          //nombre del usuario
          Center(
              child: Text(
            _isLoading ? '' : '@${user!.username}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          )),
          const SizedBox(height: 30),
          //foto de perfil
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(100),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.person,
                size: 70,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 30),
          //stats del perfil -> numero de publicaciones, seguidores, seguidos

          //follow / unfollow button

          //edit bio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Bio ",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                GestureDetector(
                  onTap: _showEditBioBox,
                  child: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          //bio box
          MyBioBox(text: _isLoading ? '...' : user!.bio), //bio del usuario
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 15),
            child: Text(
              "Posts",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          //lista de publicaciones del usuario
          allUserPosts.isEmpty
              ?

              //publicacion del usuario vacia
              Center(
                  child: Text(
                    'No hay publicaciones',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              :
              //publicacion del usuario
              ListView.builder(
                  itemCount: allUserPosts.length,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    //obtener post individual
                    final post = allUserPosts[index];
                    //post tile UI
                    return MyPostTile(
                      post: post,
                      onUserTap: () {},
                      onPostTap: () => goPostPage(context, post), 
                    );
                  },
                )
        ],
      ),
    );
  }
}
