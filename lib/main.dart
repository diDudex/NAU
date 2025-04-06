import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nau/services/auth/auth_gate.dart';
import 'package:nau/firebase_options.dart';
import 'package:nau/services/auth/database/database_provider.dart';
import '../temas/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async{
//firebase setup
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //runApp(const MainApp());
  runApp(
    MultiProvider(
      providers: [
        //tema provider
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        //base de datos provider
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
      routes: {'/': (context) => const AuthGate()},
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
