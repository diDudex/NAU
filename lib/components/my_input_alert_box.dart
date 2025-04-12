import 'package:flutter/material.dart';
/*
  MyInputAlertBox
    Este es un cuadro de diálogo de alerta que tiene un campo de texto donde el usuario puede escribir.
      se usara para cosas como editar la biografía, publicar un mensaje nuevo, etc
      -----------------------------------------------------------------------------------------------
      Este widget contiene:
      - Text Controller (pa que el usuario escriba)
      - Hint Text (ejemplo: "Escribe tu biografía")
      - Una función  (ejemplo: updateBio)
      - Texto del botón (ejemplo: "Actualizar")
*/

class MyInputAlertBox extends StatelessWidget {
  final TextEditingController textController;
  final String hintText;
  final void Function()? onPressed;
  final String onPressedText;
  const MyInputAlertBox({
    super.key,
    required this.textController,
    required this.hintText,
    required this.onPressed,
    required this.onPressedText,
  });

  //Construccion de la interfaz de usuario
  @override
  Widget build(BuildContext context) {
    //Dialogo de alerta
    return AlertDialog(
      //esquinas redondeadas
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      //color
      backgroundColor: Theme.of(context).colorScheme.secondary,
      //TextField (indica al usuario que escriba)
      content: TextField(
        controller: textController,

        //limitacion de caracteres
        maxLength: 250,
        maxLines: 4,

        //borde de cuando el campo pal texto no esta seleccionado
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
          //borde de cuando el campo pal texto esta seleccionado
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
          //hint text
          hintText: hintText,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
          //color de adentro del textfield
          fillColor: Theme.of(context).colorScheme.tertiary,
          filled: true,

          //counter style
          counterStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      //botonones
      actions: [
        //boton de cancelar
        TextButton(
          onPressed: () {
            //cerrar el dialogo
            Navigator.of(context).pop();
            //limpiar el campo de texto
            textController.clear();
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: (){                     
            //cerrar el dialogo
            Navigator.of(context).pop();
            //ejecutar la funcion
            onPressed!();

            //limpiar el campo de texto
            textController.clear();
          }, 
          child: Text(onPressedText)),
      ],
    );
  }
}
