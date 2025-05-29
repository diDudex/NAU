import 'package:flutter/material.dart';
import 'package:nau/services/auth/auth_services.dart';
/*
   Esta página contiene varias configuraciones relacionadas con la cuenta de usuario: 
   -eliminar su propia cuenta
    (esta función es un requisito si desea publicar esto en la tienda de aplicaciones)
*/

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  //confirmar eliminación
  void confirmDeletion(BuildContext context) {
   showDialog(
      context: context,
      builder: (context) => 
         AlertDialog(
          title: const Text('Eliminar cuenta'),
          content: const Text(
              '¿Estás seguro de que quieres eliminar esta cuenta?'),
          actions: [
            //cancelar
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            //eliminar
            TextButton(
              onPressed: () async {
                //eliminar cuenta
                await AuthService() .deleteAccount();
                //ir a la pantalla de login/signup
                Navigator.pushNamedAndRemoveUntil( context,
                    '/', (route) => false);
              },
              child: const Text('Eliminar cuenta'),
            ),
          ],
        ),
    );
  }

  //build UI
  @override
  Widget build(BuildContext context) {
    //Scaffold
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,

        //AppBar
        appBar: AppBar(
          title: const Text("Ajustes de cuenta"),
          foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),

        //Body
        body: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
            child: GestureDetector(
             onTap: () => confirmDeletion(context),
              child: const Text(
                "Eliminar cuenta",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ]));
  }
}
