import 'package:flutter/material.dart';

/* 

  Botton personalizado
    -----------------------------------------------------------------------------
    esto necesita:
    - texto
    - funcion al hacer clic

*/

class MyButton extends StatefulWidget {
  final String text;
  final void Function()? onTap;

  const MyButton({
    super.key,
    required this.text,
    required this.onTap,
    
    });

  @override
  State<MyButton> createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton> {
  @override
  //construccion del boton
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        //padding del boton
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          //color del boton
          color: Theme.of(context).colorScheme.secondary,
          //bordes redondeados
          borderRadius: BorderRadius.circular(10.0),
        ),
        //text
        child: Center(
          child: Text(widget.text, 
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15.0,
          ),
          )),
      ),
    );
  }
}