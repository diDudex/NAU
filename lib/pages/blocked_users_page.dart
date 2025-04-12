import 'package:flutter/material.dart';
import 'package:nau/services/auth/database/database_provider.dart';
import 'package:provider/provider.dart';
/*
  Página de usuarios bloqueados
    Esta página muestra una lista de usuarios que han sido bloqueados
    - Puedes desbloquear usuarios aquí
*/

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  //providers
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider =
      Provider.of<DatabaseProvider>(context, listen: false); 
    //al iniciar
    @override
  void initState() {
    super.initState();
    //cargar usuarios bloqueados
    loadBlockedUsers();
  }
  Future<void> loadBlockedUsers() async {
    //cargar usuarios bloqueados
    await databaseProvider.loadBlockedUsers();
  }
  //mostrar box confirm de desbloqueo
  void showUnblockDialog(String userId) {
    //show dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Desbloquear usuario"),
          content: const Text("¿Estás seguro de que quieres desbloquear a este usuario?"),
          actions: [
            TextButton(
              onPressed: () {
                //desbloquear usuario
                databaseProvider.unblockUser(userId);
                //cerrar dialog
                Navigator.pop(context);
              },
              child: const Text("Desbloquear"),
            ),
            TextButton(
              onPressed: () {
                //cerrar dialog
                Navigator.pop(context);
              },
              child: const Text("Cancelar"),
            ),
          ],
        );
      },
    );
  }

  //build UI
  @override
  Widget build(BuildContext context) {
    //listen de usuarios bloqueados
    final blockedUsers = listeningProvider.blockedUsers;
    //Scaffold
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      //AppBar
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Usuarios bloqueados"),
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      //Body
    body: blockedUsers.isEmpty
        ? const Center(
            child: Text("No hay usuarios bloqueados..."),
          )
        : ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              //usuario
              final user = blockedUsers[index];
              //Tile
              return ListTile(
                title: Text(user.username),
                subtitle: Text('@${user.username}'),
                trailing: IconButton(
                  icon: const Icon(Icons.block),
                  onPressed: () => showUnblockDialog(user.uid),
                  
                  
                  /* Sin confirmacion
                  () {
                    //desbloquear usuario
                    databaseProvider.unblockUser(user.uid);
                  },*/
                ),
              );
            },
          ),
    );
  }
}
