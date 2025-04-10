import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nau/services/auth/login_or_signup.dart';
import '../../pages/home_page.dart';
/*
Puerta de autenticacion
esto servira para checar si el usuario esta registrado o no
----------------------------------------------------------------------------------------------------------------
 Si el usuario ya esta logeado lo mandara a la pantalla de inicio
 si el usuario no esta registrado lo mandara a la pantalla de registro o login
 
*/



class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot){
        if (snapshot.hasData){
          //si el usuario esta logeado
          return const HomePage();
        } else {
          //si el usuario no esta logeado
          return const LoginOrSignup();
        }
      },
      ),
    );
  }
}