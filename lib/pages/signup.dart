import 'package:flutter/material.dart';
import 'package:nau/services/auth/auth_services.dart';
import 'package:nau/services/auth/database/database_service.dart';

import '../components/my_button.dart';
import '../components/my_loading_circle.dart';
import '../components/my_text_field.dart';

/*
Pantalla de registro
esta pantalla es la encargada de mostrar el formulario de registro
-----------------------------------------------------------------------------
Necesita:
  -titulo
  -formulario de registro
    -nombre
    -correo
    -contraseña
    -confirmar contraseña
  -boton de registro
    - este boton creara la cuenta del usuario y lo llevara a la pantalla de inicio
  --------------------------------------------------------------------------
  Si el usuario ya tiene cuenta, puede hacer clic en el boton de inicio de sesión y lo llevara a la pantalla de inicio de sesión
  -boton de "Ya tengo cuenta"

*/

class Signup extends StatefulWidget {
  final void Function() onTap;
  const Signup({super.key, required this.onTap});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  //access to auth y db service
  final _auth = AuthService();
  final _db = DatabaseService();
  //controladores de los textfields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  //botton de registro
  void register() async {
    //las contraseñas coinciden = crear usuario
    if (pwController.text == confirmPwController.text) {
      //el coso que gira de carga
      showLoadingCircle(context);
      try {
        //intentar crear usuario
        await _auth.registerEmailPassword(
            emailController.text, 
            pwController.text);
        //si se logra crear el usuario, se cierra el coso que gira de carga
        if (mounted) hideLoadingCircle(context);

        //Una vez registrado, crear y guardar el perfil de usuario en la base de datos
        await _db.saveUserInfoInFirebase(
            name: nameController.text, 
            email: emailController.text);
        //Por cierto, cada vez que agregas un nuevo paquete, es una buena idea cerrar la aplicación y reiniciarla

      }
      //cachar cualquier error
      catch (e) {
        //si se logra crear el usuario, se cierra el coso que gira de carga
        if (mounted) hideLoadingCircle(context);

        //mostrar mensaje de error
        if (mounted) {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text(e.toString()),
         ));
        }
      }
    }
    //si las contraseñas no coinciden = mostrar mensaje de error
    else  {
            showDialog(
                context: context,
                builder: (context) => const AlertDialog(
                      title: Text("¡Las contraseñas no coinciden!"),
          )
        );
      }
    }

  //construccion de la interfaz
  @override
  Widget build(BuildContext context) {
    //Scaffold
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      //Body
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 100.0),
                //logo
                Icon(
                  Icons.lock_open_rounded,
                  size: 50.0,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),

                const SizedBox(height: 50.0),
                //mensaje de crea tu cuenta
                Text(
                  "¡Crea tu propia cuenta ahora mismo!",
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),

                const SizedBox(height: 50.0),
                MyTextField(
                    controller: nameController,
                    hintText: "Escribe tu nombre...",
                    obscureText: false),
                const SizedBox(height: 50.0),
                //user-email textfield
                MyTextField(
                    controller: emailController,
                    hintText: "Ingresa tu e-mail...",
                    obscureText: false),
                const SizedBox(height: 50.0),
                //password textfield
                MyTextField(
                  controller: pwController,
                  hintText: "Ingresa tu contraseña...",
                  obscureText: true,
                ),
                const SizedBox(height: 50.0),
                //confirm password textfield
                MyTextField(
                  controller: confirmPwController,
                  hintText: "Confirma tu contraseña...",
                  obscureText: true,
                ),
                const SizedBox(height: 50.0),

                //continuar con el registro button
                MyButton(text: "Continuar", onTap: register),

                const SizedBox(height: 50.0),
                //ya tienes cuenta? inicia sesion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿Ya eres usuario?",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary),
                    ),
                    const SizedBox(width: 10.0),
                    //si el usuario no tiene cuenta lo llevara a la pantalla de registro
                    GestureDetector(
                        onTap: widget.onTap,
                        child: Text("Iniciar sesión",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                                fontWeight: FontWeight.bold))),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
