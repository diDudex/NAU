import 'package:flutter/material.dart';
import '../temas/dark_mode.dart';
import '../temas/light_mode.dart';

/*

Aqui se define  y se cambia el tema de la aplicación

*/

class ThemeProvider with ChangeNotifier{
// Tema blanco por defecto
ThemeData _themeData = lightMode;
// se obtiene el tema actual
ThemeData get themeData => _themeData;
// esta en modo oscuro?
bool get isDarkMode => _themeData == darkMode;
// Cambiar el tema
set themeData(ThemeData themeData) {
_themeData = themeData;

//actualiza el UI
notifyListeners();
}
//alternar entre los temas
void toggleTheme(){
  if (_themeData == lightMode){
    themeData = darkMode;
  }
  else{
    themeData = lightMode;
  }  
}
}