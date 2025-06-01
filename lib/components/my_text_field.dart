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
class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  
  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField( // Cambia TextField a TextFormField
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
