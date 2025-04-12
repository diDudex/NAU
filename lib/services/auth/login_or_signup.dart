import 'package:flutter/material.dart';
import 'package:nau/pages/login.dart';

import '../../pages/signup.dart';

/*
  LoginOrSignup
    esta clase es la encargada de mostrar la pantalla de inicio de sesión o registro
    --------------------------------------------------------------------------------
    Esta pantalla tendra:
      -titulo
      -boton de inicio de sesión
      -boton de registro
      --------------------------------------------------------------------------
      Si el usuario no tiene cuenta, puede hacer clic en el boton de registro y lo llevara a la pantalla de registro
      Si el usuario ya tiene cuenta, puede hacer clic en el boton de inicio de sesión y lo llevara a la pantalla de inicio de sesión
*/
class LoginOrSignup extends StatefulWidget {
  const LoginOrSignup({super.key});

  @override
  State<LoginOrSignup> createState() => _LoginOrSignupState();
}

class _LoginOrSignupState extends State<LoginOrSignup> { 
  // inicialmente mostrara la pantalla de inicio de sesión
  bool showLogin = true;
  //alternar entre las pantallas de inicio de sesión y registro
  void toggleScreen() {
    setState(() {
      showLogin = !showLogin;
    });
  }
  //construccion de la interfaz
  @override
  Widget build(BuildContext context) {
    if (showLogin){
      return Login(
        onTap: toggleScreen,
      );
    }
    else{
      return Signup(
        onTap: toggleScreen,
      );
    }
  }
}