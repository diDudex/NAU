import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nau/components/my_settings_tile.dart';
import 'package:provider/provider.dart';
import '../services/auth/auth_services.dart';
import '../temas/theme_provider.dart';

/*
    Pagina de Configuracion 
    Muestra las opciones de configuracion de la aplicacion

    -Cambiar el tema
    -Salir de la cuenta
    -Eliminar cuenta

*/
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

//Construccion de la interfaz
class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    //Scaffold
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        //AppBar
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Ajustes",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          ),
          foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        //Body
        body: Column(
          children: [
            MySettingsTile(
              title: "Cambiar tema",
              action: CupertinoSwitch(
                onChanged: (value) =>
                    Provider.of<ThemeProvider>(context, listen: false)
                        .toggleTheme(),
                value: Provider.of<ThemeProvider>(context, listen: false)
                    .isDarkMode,
              ),
            ),
            MySettingsTile(
              title: "Configuración de perfil",
              action: IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).pushNamed('/perfilconfig');
                },
              ),
            ),
            MySettingsTile(
              title: "Validacion de Documentos",
              action: IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: () {
                  Navigator.of(context).pushNamed('/document_page');
                },
              ),
            ),
            MySettingsTile(
              title: "Panel de Administrador",
              action: IconButton(
                icon: const Icon(Icons.admin_panel_settings),
                onPressed: () {
                  Navigator.of(context).pushNamed('/admin_panel');
                },
              ),
            ),
            MySettingsTile(
              title: "Editor de Rutas",
              action: IconButton(
                icon: const Icon(Icons.edit_road),
                onPressed: () {
                  Navigator.of(context).pushNamed('/RouteEditorScreen');
                },
              ),
            ),
            MySettingsTile(
              title: "Salir de la cuenta",
              action: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final authService =
                      Provider.of<AuthService>(context, listen: false);
                  await authService.logout();
                  if (!mounted) return;
                  navigator.pushReplacementNamed('/login');
                },
              ),
            ),

          ],
        ));
  }
}
