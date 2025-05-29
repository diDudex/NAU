import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketW extends StatefulWidget {
  const TicketW({super.key});

  @override
  State<TicketW> createState() => _TicketWState();
}

class _TicketWState extends State<TicketW> {
  final GlobalKey _ticketKey = GlobalKey();
  int cantidad = 1;
  bool comprado = false;
  Uint8List? ticketImage;

  final double precioUnitario = 20.0;
  final double descuentoFijo = 5.0;
  final double impuestosFijos = 2.0;

  @override
  Widget build(BuildContext context) {
    final double subtotal = precioUnitario * cantidad;
    final double impuestos = impuestosFijos;
    final double descuento = descuentoFijo;
    final double total = (subtotal + impuestos) - descuento;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (ticketImage != null)
            Image.memory(ticketImage!)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RepaintBoundary(
                  key: _ticketKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "TICKET DE COMPRA",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        QrImageView(
                          data: 'ticket_id_urbanos_12',
                          size: 300,
                        ),
                        const SizedBox(height: 20),
                        infoText("Nombre", "Urbanos"),
                        infoText("Número de camión", "12"),
                        infoText("Ruta", "Angostura-Guamuchil"),
                        infoText("Destino", "Guamuchil"),
                        infoText("Cantidad", "$cantidad"),
                        const SizedBox(height: 10),
                        const Divider(),
                        infoText("Subtotal", "\$${subtotal.toStringAsFixed(2)}"),
                        infoText("Impuestos", "\$${impuestos.toStringAsFixed(2)}"),
                        infoText("Descuento", "-\$${descuento.toStringAsFixed(2)}"),
                        const SizedBox(height: 10),
                        Text(
                          "Total: \$${total.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (!comprado)
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('tickets').add({
                          'nombre': 'Urbanos',
                          'numeroCamion': 12,
                          'ruta': 'Angostura-Guamuchil',
                          'destino': 'Guamuchil',
                          'cantidad': cantidad,
                          'subtotal': subtotal,
                          'impuestos': impuestos,
                          'descuento': descuento,
                          'total': total,
                          'fecha': DateTime.now(),
                        });
                        setState(() => comprado = true);
                      },
                      child: const Text('Comprar'),
                    ),
                  )
                else
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Mostrar Boleto'),
                      onPressed: generarImagenTicket,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget infoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        "$label: $value",
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  Future<void> generarImagenTicket() async {
    try {
      RenderRepaintBoundary boundary = _ticketKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      setState(() {
        ticketImage = pngBytes;
      });
    } catch (e) {
      debugPrint("Error al generar imagen del ticket: $e");
    }
  }
}
