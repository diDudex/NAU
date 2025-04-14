class Ruta {
  final String origen;
  final String destino;
  final int tiempo;

  Ruta({required this.origen, required this.destino, required this.tiempo});

  factory Ruta.fromMap(Map<String, dynamic> data) {
    return Ruta(
      origen: data['origen'] ?? '',
      destino: data['destino'] ?? '',
      tiempo: data['tiempo'] ?? 0,
    );
  }
}
