import 'package:flutter/material.dart';

/*

  Lista SettingsTile personalizada
    Esta clase es un componente que se puede utilizar en cualquier parte de la aplicación para mostrar una lista de ajustes
    ----------------------------------------------------------------------------

    para usar este widget se necesita:

      -titulo (ejemplo "Modo oscuro")
      -icono (ejemplo Icons.brightness_4)
      -accion (ejemplo cambiar el tema a oscuro (toggleTheme) )

*/

class MySettingsTile extends StatefulWidget {
  final String title;
  final Widget action;

  const MySettingsTile({
    super.key,     
    required this.title,
    required this.action

    });

  @override
  State<MySettingsTile> createState() => _MySettingsTileState();
}

class _MySettingsTileState extends State<MySettingsTile> {

  //construccion de la interfaz
  @override
  Widget build(BuildContext context) {
    //container
    return Container(
      decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(10.0)
            
          ),
        padding: const EdgeInsets.all(20.0),
     
      margin: const EdgeInsets.only(left: 15.0, right: 15.0, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //titulo
          Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          //accion
          widget.action,
        ],
      )
    );
  }
}