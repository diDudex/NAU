import 'package:flutter/material.dart';

/*
  Drawer tile
  esa cosa es como un moldelo de un item de un menu

  ----------------------------------------------------
    Este widget tendra:
      -icono (ejemplo Icons.home)
      -titulo (ejemplo "Home")
      -accion (ejemplo navegar a la pagina de inicio (goToHomePage) )
*/
class MyDrawerTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final void Function()? onTap;

  const MyDrawerTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    });

  @override
  State<MyDrawerTile> createState() => _MyDrawerTileState();
}

//construccion de la interfaz
class _MyDrawerTileState extends State<MyDrawerTile> {
  @override
  Widget build(BuildContext context) {
    //list tile
    return ListTile(
      title: Text(
        widget.title,
        style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
      ),
      leading: Icon(widget.icon, 
      color: Theme.of(context).colorScheme.primary
      ),
      onTap: widget.onTap,
    );
  }
}
