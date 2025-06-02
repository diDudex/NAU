import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nau/components/my_settings_tile.dart';
import 'package:provider/provider.dart';
import '../services/auth/auth_services.dart';
import '../temas/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Ajustes",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
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
            title: "Validación de Documentos",
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
                Navigator.of(context).pushNamed('/paneladmin');
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
      ),
    );
  }
}
