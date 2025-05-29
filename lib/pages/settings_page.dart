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
            MySettingsTile(
              title: "Eliminar cuenta",
              action: IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () async {
                final authService =
                  Provider.of<AuthService>(context, listen: false);

                // Opcional: mostrar un diálogo de confirmación
                final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('¿Eliminar cuenta?'),
                  content: const Text(
                    'Esta acción no se puede deshacer. ¿Seguro que quieres eliminar tu cuenta?'),
                  actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Eliminar',
                      style: TextStyle(color: Colors.red)),
                  ),
                  ],
                ),
                );

                if (confirm == true) {
                try {
                  await authService.deleteAccount();
                  if (!context.mounted) return;
                  // Cierra todas las rutas y navega al login
                  Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  // Muestra un mensaje de error si ocurre algo
                  if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                    title: const Text('Error'),
                    content: Text(e.toString()),
                    actions: [
                      TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                      ),
                    ],
                    ),
                  );
                  }
                }
                }
              },
              ),
            ),
          ],
        ));
  }
}
