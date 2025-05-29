import 'package:cloud_firestore/cloud_firestore.dart';
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

  final List<int> days = List.generate(31, (i) => i + 1);
  final List<int> months = List.generate(12, (i) => i + 1);
  final List<int> years = List.generate(
    DateTime.now().year - 1899,
    (i) => 1900 + i,
  );

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

  Future<bool> _showError(String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(title: Text(message)),
    );
    return false;
  }

  /// Valida los campos del formulario de registro.
  ///
  /// Realiza las siguientes validaciones:
  ///
  /// - **Fecha de nacimiento**:
  ///   - Verifica que los campos de día, mes y año no estén vacíos.
  ///   - Asegura que los valores sean numéricos y que el año tenga 4 dígitos.
  ///   - Comprueba que la fecha sea válida, tenga sentido (por ejemplo, no sea futura, ni anterior a 1900, ni que la edad supere los 120 años).
  ///
  /// - **Correo electrónico**:
  ///   - Verifica que no esté vacío.
  ///   - Valida el formato del correo usando una expresión regular.
  ///
  /// - **Nombre**:
  ///   - Verifica que no esté vacío.
  ///   - Solo permite letras y espacios (sin caracteres especiales).
  ///
  /// - **Teléfono**:
  ///   - Verifica que no esté vacío.
  ///   - Solo permite dígitos numéricos.
  ///   - Debe tener al menos 10 dígitos.
  ///
  /// - **Contraseña**:
  ///   - Verifica que no esté vacía.
  ///   - Debe tener al menos 9 caracteres.
  ///
  /// Si alguna validación falla, muestra un mensaje de error y retorna `false`.
  /// Si todas las validaciones son correctas, retorna `true`.
  Future<bool> _validateInputs() async {
    const int minYearAllowed = 1900;
    const int maxAgeAllowed = 120;

    bool isValidDate(int year, int month, int day) {
      try {
        final date = DateTime(year, month, day);
        final now = DateTime.now();
        final age = now.year -
            date.year -
            ((now.month < date.month ||
                    (now.month == date.month && now.day < date.day))
                ? 1
                : 0);
        return date.year == year &&
            date.month == month &&
            date.day == day &&
            year >= minYearAllowed &&
            year <= now.year &&
            age <= maxAgeAllowed &&
            date.isBefore(now);
      } catch (_) {
        return false;
      }
    }

    // Validar que se haya seleccionado la fecha correctamente
    if (selectedDay == null || selectedMonth == null || selectedYear == null) {
      return await _showError("Por favor selecciona una fecha válida");
    }

    final day = selectedDay!;
    final month = selectedMonth!;
    final year = selectedYear!;

    if (!isValidDate(year, month, day)) {
      return await _showError(
          "¡La fecha de nacimiento no es válida o no tiene sentido!");
    }

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
      return await _showError(
          "¡El nombre no puede contener caracteres especiales!");
    }

    // Validación del teléfono
    if (phoneController.text.isEmpty) {
      return await _showError("¡El número de teléfono no puede estar vacío!");
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(phoneController.text)) {
      return await _showError(
          "¡El número de teléfono solo puede contener dígitos!");
    }
    if (phoneController.text.length < 10) {
      return await _showError(
          "¡El número de teléfono debe tener al menos 10 dígitos!");
    }

    // Validación de la contraseña
    if (pwController.text.isEmpty) {
      return await _showError("¡La contraseña no puede estar vacía!");
    }
    if (pwController.text.length < 9) {
      return await _showError(
          "¡La contraseña debe tener al menos 9 caracteres!");
    }

    return true;
  }

  //funcion para registrar al usuario
  //esta funcion se encarga de registrar al usuario en firebase
  //y guardar su informacion en la base de datos
  //si el registro es exitoso, lo lleva a la pantalla de inicio
  //si el registro falla, muestra un mensaje de error
  //si el usuario ya tiene cuenta, lo lleva a la pantalla de inicio de sesion
  void register() async {
    if (pwController.text != confirmPwController.text) {
      await _showError("¡Las contraseñas no coinciden!");
      return;
    }

    if (!await _validateInputs()) return;

    showLoadingCircle(context);

    try {
      await _auth.registerEmailPassword(
          emailController.text, pwController.text);

      if (mounted) hideLoadingCircle(context);

      // Convertir fecha para guardar usando variables seleccionadas
      final birthDate = DateTime(selectedYear!, selectedMonth!, selectedDay!);

      await _db.saveUserInfoInFirebase(
        name: nameController.text,
        lastName: lastNameController.text,
        email: emailController.text,
        phoneNumber: phoneController.text,
        birthDate: Timestamp.fromDate(birthDate),
      );
    } catch (e) {
      if (mounted) hideLoadingCircle(context);
      await _showError(e.toString());
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
                  const SizedBox(height: 100.0),
                  //logo
                  Icon(
                    Icons.directions_bus,
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
                  //user-name textfield
                  const SizedBox(height: 50.0),
                  MyTextField(
                      controller: nameController,
                      hintText: "Escribe tu nombre...",
                      obscureText: false),
                  const SizedBox(height: 50.0),
                  //user-lastname textfield
                  MyTextField(
                      controller: lastNameController,
                      hintText: "Escribe tus apellidos...",
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
                  //phone number textfield
                  MyTextField(
                    controller: phoneController,
                    hintText: "Ingresa tu número de teléfono...",
                    obscureText: false,
                  ),
                  const SizedBox(height: 50.0),
                  // fecha de nacimiento
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Día',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedDay,
                            items: days
                                .map((day) => DropdownMenuItem(
                                      value: day,
                                      child: Text(day.toString()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedDay = value;
                                dayController.text = value.toString();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Mes',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedMonth,
                            items: months
                                .map((month) => DropdownMenuItem(
                                      value: month,
                                      child: Text(month.toString()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedMonth = value;
                                monthController.text = value.toString();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Año',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedYear,
                            items: years
                                .map((year) => DropdownMenuItem(
                                      value: year,
                                      child: Text(year.toString()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedYear = value;
                                yearController.text = value.toString();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
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
