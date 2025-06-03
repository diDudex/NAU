import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nau/utilities/date_selector.dart';
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
        -Numero de telefono
        -Fecha de nacimiento
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
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dayController = TextEditingController();
  final TextEditingController monthController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  // Variables para controlar el valor seleccionado en los dropdowns
  int? selectedDay;
  int? selectedMonth;
  int? selectedYear;

  static const emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const nameRegex = r'^[a-zA-Z\sáéíóúÁÉÍÓÚñÑ]+$'; // Permite acentos y ñ
  static const phoneRegex = r'^[0-9]{10,}$'; // Exactamente 10+ dígitos
  static const minPasswordLength = 9;
  static const minAge = 13; // Edad mínima requerida
  static const maxAge = 120; // Edad máxima razonable


  @override
  void initState() {
    super.initState();

    // Inicializar los controladores con valores predeterminados si están vacíos
    dayController.text = dayController.text.isEmpty ? '1' : dayController.text;
    monthController.text =
        monthController.text.isEmpty ? '1' : monthController.text;
    yearController.text =
        yearController.text.isEmpty ? '2000' : yearController.text;

    selectedDay = int.tryParse(dayController.text);
    selectedMonth = int.tryParse(monthController.text);
    selectedYear = int.tryParse(yearController.text);
  }

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    pwController.dispose();
    confirmPwController.dispose();
    phoneController.dispose();
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.dispose();
  }

  Future<bool> _showError(String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(title: Text(message)),
    );
    return false;
  }

  bool _isValidBirthDate(int day, int month, int year) {
    try {
      final date = DateTime(year, month, day);
      final now = DateTime.now();
      final age = now.year -
          year -
          ((now.month < month || (now.month == month && now.day < day))
              ? 1
              : 0);

      return date.year == year &&
          date.month == month &&
          date.day == day &&
          year >= 1900 &&
          age >= minAge &&
          age <= maxAge &&
          date.isBefore(now);
    } catch (_) {
      return false;
    }
  }

  // Validar los campos de entrada
  Future<bool> _validateInputs() async {
    // Validación de fecha
    if (selectedDay == null || selectedMonth == null || selectedYear == null) {
      return await _showError("Por favor selecciona una fecha válida");
    }

    if (!_isValidBirthDate(selectedDay!, selectedMonth!, selectedYear!)) {
      return await _showError(
          "Debes tener al menos $minAge años para registrarte");
    }

    // Validación de nombre
    if (nameController.text.isEmpty || lastNameController.text.isEmpty) {
      return await _showError("Nombre y apellido son obligatorios");
    }

    if (!RegExp(nameRegex).hasMatch(nameController.text) ||
        !RegExp(nameRegex).hasMatch(lastNameController.text)) {
      return await _showError(
          "Nombre y apellido solo pueden contener letras y espacios");
    }

    // Validación de email
    if (emailController.text.isEmpty) {
      return await _showError("El correo es obligatorio");
    }

    if (!RegExp(emailRegex).hasMatch(emailController.text)) {
      return await _showError("Ingresa un correo electrónico válido");
    }

    // Validación de teléfono
    if (phoneController.text.isEmpty) {
      return await _showError("El teléfono es obligatorio");
    }

    if (!RegExp(phoneRegex).hasMatch(phoneController.text)) {
      return await _showError("El teléfono debe tener al menos 10 dígitos");
    }

    // Validación de contraseña
    if (pwController.text.length < minPasswordLength) {
      return await _showError(
          "La contraseña debe tener al menos $minPasswordLength caracteres");
    }

    if (pwController.text != confirmPwController.text) {
      return await _showError("Las contraseñas no coinciden");
    }

    return true;
  }

  // Funcion para registrar al usuario
  void register() async {
    showLoadingCircle(context);

    try {
      // Validar primero
      if (!await _validateInputs()) {
        if (mounted) hideLoadingCircle(context);
        return;
      }

      // Registrar usuario
      final userCredential = await _auth.registerEmailPassword(
          emailController.text, pwController.text);

      // Guardar información adicional
      final birthDate = DateTime(selectedYear!, selectedMonth!, selectedDay!);

      await _db.saveUserInfoInFirebase(
        name: nameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
        phoneNumber: phoneController.text,
        birthDate: Timestamp.fromDate(birthDate),
      );

      if (mounted) hideLoadingCircle(context);
    } on FirebaseAuthException catch (e) {
      if (mounted) hideLoadingCircle(context);
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = "Este correo ya está registrado";
          break;
        case 'weak-password':
          message = "La contraseña es muy débil";
          break;
        case 'invalid-email':
          message = "Correo electrónico inválido";
          break;
        default:
          message = "Error de autenticación: ${e.message}";
      }

      await _showError(message);
    } catch (e) {
      if (mounted) hideLoadingCircle(context);
      await _showError("Ocurrió un error inesperado");
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
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),
                  //logo
                  Icon(
                    Icons.directions_bus,
                    size: 50.0,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),

                  const SizedBox(height: 30.0),
                  //mensaje de crea tu cuenta
                  Text(
                    "¡Crea tu propia cuenta ahora mismo!",
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  //user-name textfield
                  const SizedBox(height: 25),
                  MyTextField(
                      controller: nameController,
                      hintText: "Escribe tu nombre...",
                      obscureText: false),
                  const SizedBox(height: 25),
                  //user-lastname textfield
                  MyTextField(
                      controller: lastNameController,
                      hintText: "Escribe tus apellidos...",
                      obscureText: false),
                  const SizedBox(height: 25),
                  //user-email textfield
                  MyTextField(
                      controller: emailController,
                      hintText: "Ingresa tu e-mail...",
                      obscureText: false),
                  const SizedBox(height: 25),
                  //password textfield
                  MyTextField(
                    controller: pwController,
                    hintText: "Ingresa tu contraseña...",
                    obscureText: true,
                  ),
                  const SizedBox(height: 25),
                  //confirm password textfield
                  MyTextField(
                    controller: confirmPwController,
                    hintText: "Confirma tu contraseña...",
                    obscureText: true,
                  ),
                  const SizedBox(height: 25),
                  //phone number textfield
                  MyTextField(
                    controller: phoneController,
                    hintText: "Ingresa tu número de teléfono...",
                    obscureText: false,
                  ),
                  const SizedBox(height: 25),
                  // fecha de nacimiento
                  DateSelector(
                    onDateChanged: (date) {
                      setState(() {
                        selectedDay = date.day;
                        selectedMonth = date.month;
                        selectedYear = date.year;
                        // Actualiza los controladores si los necesitas para otra cosa
                        dayController.text = date.day.toString();
                        monthController.text = date.month.toString();
                        yearController.text = date.year.toString();
                      });
                    },
                    initialDate: DateTime(selectedYear ?? 2000,
                        selectedMonth ?? 1, selectedDay ?? 1),
                  ),
                  const SizedBox(height: 25),

                  //continuar con el registro button
                  MyButton(text: "Continuar", onTap: register),

                  const SizedBox(height: 20.0),
                  //ya tienes cuenta? inicia sesion
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "¿Ya eres usuario?",
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.inversePrimary),
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
      ),
    );
  }
}
