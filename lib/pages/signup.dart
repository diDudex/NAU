import 'package:flutter/material.dart';
import 'package:nau/services/auth/auth_services.dart';
import 'package:nau/services/auth/database/database_service.dart';

import '../components/my_button.dart';
import '../components/my_loading_circle.dart';
import '../components/my_text_field.dart';

class Signup extends StatefulWidget {
  final void Function() onTap;
  const Signup({super.key, required this.onTap});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _auth = AuthService();
  final _db = DatabaseService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  Future<bool> _showError(String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(title: Text(message)),
    );
    return false;
  }

  Future<bool> _validateInputs() async {
    // Validación del correo
    if (emailController.text.isEmpty) {
      return await _showError("¡El correo no puede estar vacío!");
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(emailController.text)) {
      return await _showError("¡El correo no tiene un formato válido!");
    }

    // Validación del nombre
    if (nameController.text.isEmpty) {
      return await _showError("¡El nombre no puede estar vacío!");
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(nameController.text)) {
      return await _showError("¡El nombre no puede contener caracteres especiales!");
    }

    // Validación de la contraseña
    if (pwController.text.isEmpty) {
      return await _showError("¡La contraseña no puede estar vacía!");
    }
    if (pwController.text.length < 9) {
      return await _showError("¡La contraseña debe tener al menos 9 caracteres!");
    }

    return true;
  }

  void register() async {
    if (pwController.text != confirmPwController.text) {
      await _showError("¡Las contraseñas no coinciden!");
      return;
    }

    if (!await _validateInputs()) return;

    showLoadingCircle(context);

    try {
      await _auth.registerEmailPassword(emailController.text, pwController.text);

      if (mounted) hideLoadingCircle(context);

      await _db.saveDriverInfoInFirebase(
        name: nameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
      );
    } catch (e) {
      if (mounted) hideLoadingCircle(context);
      await _showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 100.0),
                  Icon(
                    Icons.directions_bus,
                    size: 50.0,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  const SizedBox(height: 50.0),
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
                    obscureText: false,
                  ),
                  const SizedBox(height: 50.0),
                  MyTextField(
                    controller: lastNameController,
                    hintText: "Escribe tus apellidos...",
                    obscureText: false,
                  ),
                  const SizedBox(height: 50.0),
                  MyTextField(
                    controller: emailController,
                    hintText: "Ingresa tu e-mail...",
                    obscureText: false,
                  ),
                  const SizedBox(height: 50.0),
                  MyTextField(
                    controller: pwController,
                    hintText: "Ingresa tu contraseña...",
                    obscureText: true,
                  ),
                  const SizedBox(height: 50.0),
                  MyTextField(
                    controller: confirmPwController,
                    hintText: "Confirma tu contraseña...",
                    obscureText: true,
                  ),
                  const SizedBox(height: 50.0),
                  MyButton(
                    text: "Registrarse",
                    onTap: register,
                  ),
                  const SizedBox(height: 20.0),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      "¿Ya tienes cuenta? Inicia sesión",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
