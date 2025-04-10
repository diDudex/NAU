import 'package:flutter/material.dart';
import 'package:nau/services/auth/auth_services.dart';
import '../components/my_drawer_tile.dart';

import '../pages/profile_page.dart';
import '../pages/settings_page.dart';

/*
 Drawer
 este es un coso de menú al que generalmente se accede 
 desde el lado izquierdo de las appbar
 -------------------------------------------------------------------
 Este menu tendra:
  -Home 
  -Perfil
  -Buscar
  -Configuración
  -Cerrar sesión
*/
class MyDrawer extends StatelessWidget {
  MyDrawer({super.key});
  //Servicios de autenticación
  //funcion de cerrar sesión
  final _auth = AuthService();
  //metodo de cerrar sesión
  void Logout() {
    _auth.logout();
  }

  //construccion de la interfaz
  @override
  Widget build(BuildContext context) {
    //Drawer
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Column(
            children: [
              //app logo
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Icon(
                  Icons.person,
                  size: 60.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              //linea divisoria
              Divider(
                color: Theme.of(context).colorScheme.inversePrimary,
                thickness: 1.5,
              ),
              const SizedBox(height: 50.0),
              //titulo de home
              MyDrawerTile(
                title: 'Inicio',
                icon: Icons.home,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              //titulo de perfil
              MyDrawerTile(
                title: 'Perfil',
                icon: Icons.person,
                onTap: () {
                  Navigator.pop(context);

                  //ir a pa pagina de perfil
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          uid: _auth.getCurrentUid(),
                        ),
                      ));
                },
              ),
              //titulo de buscar
              MyDrawerTile(
                title: 'Buscar',
                icon: Icons.search,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              //titulo de configuración
              MyDrawerTile(
                title: 'Configuración',
                icon: Icons.settings,
                onTap: () {
                  //pop menu drawer
                  Navigator.pop(context);

                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ));
                },
              ),

              //titulo de cerrar sesión
              MyDrawerTile(
                title: 'Cerrar sesión',
                icon: Icons.logout,
                onTap: Logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
