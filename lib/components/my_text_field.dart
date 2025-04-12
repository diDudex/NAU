import 'package:flutter/material.dart';

/* 
  TextField
    la chingadera donde se puede escribir
    --------------------------------------
    debe de tener:
    - Text controller
    - sugerencias (ejemplo: "Escribe tu nombre")
    - ocultar contraseña (ejemplo: ********)
*/
class MyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  const MyTextField(
      {
      super.key,
      required this.controller,
      required this.hintText,
      required this.obscureText,
      });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  //construccion de la interfaz
  @override
  Widget build(BuildContext context) {
    //TextField
    return TextField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      decoration: InputDecoration(
        //borde cuando no esta seleccionado
        enabledBorder: OutlineInputBorder
        (
          borderSide: BorderSide(color: Theme.of(context).colorScheme.inversePrimary),
          borderRadius: BorderRadius.circular(10.0),
        ),
        //borde cuando esta seleccionado
        focusedBorder: OutlineInputBorder
        (
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(10.0),
        ),
        fillColor: Theme.of(context).colorScheme.tertiary,
        filled: true,
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
