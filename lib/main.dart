import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nau/pages/login.dart';
import 'package:nau/pages/perfilconfig.dart';
import 'package:nau/services/auth/auth_gate.dart';
import 'package:nau/firebase_options.dart';
import 'package:nau/services/auth/database/database_provider.dart';
import '../temas/theme_provider.dart';
import 'package:provider/provider.dart';

import 'services/auth/auth_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Verifica si Firebase ya está inicializado
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        // Servicio de autenticación
        Provider<AuthService>(create: (_) => AuthService(),
        ),
        // Tema provider
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // Base de datos provider
        ChangeNotifierProvider(create: (context) => DatabaseProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const Login(),
        '/perfilconfig': (context) {
          final userId = AuthService().getCurrentUid();
          return PerfilConfig(userId: userId);
        },
      },
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
