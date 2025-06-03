import 'package:flutter/material.dart';
import 'package:nau/components/my_button.dart';
import 'package:nau/components/my_loading_circle.dart';
import 'package:nau/components/my_text_field.dart';
import 'package:nau/pages/signup.dart';
import 'package:nau/services/auth/auth_services.dart';
import 'package:nau/utilities/forgpass.dart';

/*
  LoginPage
    esta pantalla es la encargada de mostrar el formulario de inicio de sesión
    -----------------------------------------------------------------------------
    Esta pantalla tendra:
      -titulo
      -formulario de inicio de sesión
      -boton de inicio de sesión
      --------------------------------------------------------------------------
      Si el usuario no tiene cuenta, puede hacer clic en el boton de registro y lo llevara a la pantalla de registro
      -boton de registro
*/
class Login extends StatefulWidget {
  final void Function()? onTap;

  const Login({super.key, this.onTap});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  //accesos a auth service
  final _auth = AuthService();

  //controladores de los textfields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();

  //metodo de inicio de sesion
  void login() async {
    //el coso que gira de carga
    showLoadingCircle(context);
    try {
      //intentar iniciar sesion
      await _auth.loginEmailPassword(emailController.text, pwController.text);
      //si se logra iniciar sesion, se cierra el coso que gira de carga
      if (mounted) hideLoadingCircle(context);
    }
    //cachar cualquier error
    catch (e) {
      //si se logra iniciar sesion, se cierra el coso que gira de carga
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  //logo
                  Icon(
                    Icons.directions_bus,
                    size: 50.0,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),

                  const SizedBox(height: 50.0),
                  //mensaje de bienvenida
                  Text(
                    "Bienvenido a NAU",
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 50.0),
                  // Botón de inicio de sesión con huella digital
                  IconButton(
                    icon: Icon(
                      Icons.fingerprint,
                      size: 40.0,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    tooltip: 'Iniciar sesión con huella',
                    onPressed: () async {
                      // Aquí deberías implementar la autenticación biométrica
                      // usando un paquete como local_auth
                      // Ejemplo básico:
                      // final isAuthenticated = await LocalAuthService.authenticate();
                      // if (isAuthenticated) { /* Lógica de inicio de sesión */ }
                      showDialog(
                        context: context,
                        builder: (context) => const AlertDialog(
                          title: Text('Función no implementada'),
                          content: Text(
                              'Aquí irá el inicio de sesión con huella digital.'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 50.0),
                  //user-email textfield
                  MyTextField(
                      controller: emailController,
                      hintText: "Ingresa tu e-mail o usuario...",
                      obscureText: false),
                  const SizedBox(height: 50.0),
                  //password textfield
                  MyTextField(
                    controller: pwController,
                    hintText: "Ingresa tu contraseña...",
                    obscureText: true,
                  ),
                  const SizedBox(height: 20.0),
                  //olvidaste tu password?
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen()));
                    },
                    child: Container(
                        alignment: Alignment.topRight,
                        child: Text("¿Olvidaste tu contraseña?",
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                              fontSize: 15.0,
                            ))),
                  ),
                  const SizedBox(height: 50.0),
                  //sig in button
                  MyButton(text: "Iniciar Sesión", onTap: login),

                  const SizedBox(height: 50.0),
                  //no tienes cuenta? registrate
                  const SizedBox(height: 70.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Signup(onTap: () {
                                  Navigator.pop(context);
                                })),
                      );
                    },
                    child: Text(
                      "¿No tienes una cuenta? Regístrate",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        fontSize: 15.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
