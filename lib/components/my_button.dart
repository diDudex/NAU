import 'package:flutter/material.dart';

/* 

  Botton personalizado
  -----------------------------------------------------------------------------
  esto necesita:
  - texto
  - funcion al hacer clic

*/

class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  
  const MyButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        // Usa el color proporcionado o el color primario del tema por defecto
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.inversePrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}