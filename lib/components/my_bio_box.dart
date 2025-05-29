import 'package:flutter/material.dart';

/*
  MyBioBox
  Este es un cuadro simple con texto adentro. Sse usara para la biografía del usuario 
  en sus páginas de perfil
  -----------------------------------------------------------------------------------------------
  Este widget contiene solo un texto, pero se puede personalizar para contener más cosas

*/
class MyBioBox extends StatelessWidget {
  final String text;
  const MyBioBox({super.key, required this.text});

  @override
  //build de la interfaz de usuario
  Widget build(BuildContext context) {
    //container
    return Container(
      //padding de afuera
      margin: const EdgeInsets.symmetric(horizontal: 15),
      //padding
      padding: const EdgeInsets.all(10),
      //decoracion
      decoration: BoxDecoration(
        //color
        color: Theme.of(context).colorScheme.tertiary,
        //bordes redondeados
        borderRadius: BorderRadius.circular(10),
      ),

      //padding de afuera
      //margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        //muestra esto si no tiene bio
        text.isNotEmpty ? text : '',
        style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
      ),
    );
  }
}
