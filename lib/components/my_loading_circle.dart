import 'package:flutter/material.dart';
/*
 Circulo de carga
*/

//ver el circulo de carga
void showLoadingCircle(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: Center(
        child: CircularProgressIndicator(),
      ),
    )
  );
}
void hideLoadingCircle(BuildContext context) {
  Navigator.of(context).pop();
}