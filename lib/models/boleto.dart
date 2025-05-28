class Boleto {
  final int asiento;
  final String ruta;
  final DateTime fecha;
  final String hora;
  final double precio;

  Boleto({
    required this.asiento,
    required this.ruta,
    required this.fecha,
    required this.hora,
    required this.precio,
  });

  Map<String, dynamic> toMap() {
    return {
      'asiento': asiento,
      'ruta': ruta,
      'fecha': fecha.toIso8601String(),
      'hora': hora,
      'precio': precio,
    };
  }
}
