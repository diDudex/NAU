import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nau/components/my_settings_tile.dart';
import 'package:provider/provider.dart';
import 'package:nau/helper/navigate_pages.dart';
import '../temas/theme_provider.dart';

/*
    Pagina de Configuracion 
    Muestra las opciones de configuracion de la aplicacion

    -Cambiar el tema
    -Usuarios bloqueados
    -Ajustes de cuenta
    -Acerca de
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
          title: const Text("Ajustes"),
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
              title: "Usuarios bloqueados",
              action: IconButton(
                onPressed: () => goBlockedUsersPage(context),
                icon: Icon(Icons.arrow_forward_ios,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ),

            MySettingsTile(
              title: "Ajustes de cuenta",
              action: IconButton(
                onPressed: () => goAccountSettingsPage(context),
                icon: Icon(Icons.arrow_forward_ios,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ));
  }
}
