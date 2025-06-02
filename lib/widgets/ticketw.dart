import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/boleto.dart';

class TicketW extends StatefulWidget {
  final List<Boleto> boletos;
  final String busRouteId;
  final VoidCallback onTicketPurchased;

  const TicketW({
    super.key,
    required this.boletos,
    required this.busRouteId,
    required this.onTicketPurchased,
  });

  @override
  State<TicketW> createState() => _TicketWState();
}

class _TicketWState extends State<TicketW> {
  final GlobalKey _ticketKey = GlobalKey();
  // Variables para manejar el estado de compra y generación de imagen
  bool _comprado = false;
  Uint8List? _ticketImage;
  bool _guardando = false;
  double _total = 0.0;
  List<String> _boletosIds = [];
  bool _shouldRefresh = false;

  @override
  void initState() {
    super.initState();
    _total = widget.boletos.fold(0.0, (sum, boleto) => sum + boleto.precio);
  }

  @override
  void dispose() {
    if (_shouldRefresh) {
      widget.onTicketPurchased();
    }
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_shouldRefresh) {
      widget.onTicketPurchased();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final firstBoleto = widget.boletos.first;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.boletos.length == 1
              ? 'Tu Boleto'
              : 'Tus Boletos (${widget.boletos.length})'),
          centerTitle: true,
          actions: [
            if (_comprado)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, true),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              RepaintBoundary(
                key: _ticketKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        widget.boletos.length == 1
                            ? "BOLETO DE AUTOBÚS"
                            : "BOLETOS DE AUTOBÚS",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        dateFormat.format(firstBoleto.fecha),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // QR que cambia según el estado de compra
                      _comprado
                          ? QrImageView(
                              data: 'boleto_${_boletosIds.join('_')}',
                              size: 200,
                              backgroundColor: Colors.white,
                            )
                          : Column(
                              children: [
                                Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Text(
                                      'QR disponible\ndespués de la compra',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'El QR se habilitará después del pago',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 20),
                      _buildInfoRow('Ruta:', firstBoleto.ruta),
                      _buildInfoRow('Hora:', firstBoleto.hora),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Asientos:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: widget.boletos
                                  .map((boleto) => Chip(
                                        label: Text('${boleto.asiento}'),
                                        backgroundColor: _comprado
                                            ? Colors.blue
                                            : Colors.blue.withOpacity(0.5),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total (${widget.boletos.length} boleto${widget.boletos.length > 1 ? 's' : ''}):',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _comprado
                            ? 'Presentar este boleto al abordar'
                            : 'Complete la compra para habilitar el boleto',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (!_comprado)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: _guardando ? null : _comprarBoletos,
                    child: _guardando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Confirmar ${widget.boletos.length} Boleto${widget.boletos.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                  ),
                )
              else
                Column(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      '¡${widget.boletos.length} Boleto${widget.boletos.length > 1 ? 's' : ''} comprado${widget.boletos.length > 1 ? 's' : ''} exitosamente!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Guardar Boleto(s)'),
                        onPressed: _generarImagenTicket,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      child: const Text('Volver a la lista de rutas'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _comprarBoletos() async {
    setState(() {
      _guardando = true;
      _shouldRefresh = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final ticketsRef = FirebaseFirestore.instance.collection('Boletos');
      _boletosIds = [];

      // 1. Crear documentos de boletos
      for (final boleto in widget.boletos) {
        final docRef = ticketsRef.doc();
        _boletosIds.add(docRef.id);

        batch.set(docRef, {
          'id': docRef.id,
          'ruta': boleto.ruta,
          'asiento': boleto.asiento,
          'fecha': boleto.fecha,
          'hora': boleto.hora,
          'precio': boleto.precio,
          'fechaCompra': FieldValue.serverTimestamp(),
          'estado': 'activo',
          'rutaId': widget.busRouteId,
          'qrData': 'boleto_${docRef.id}',
        });
      }

      // 2. Actualizar estado de asientos en la ruta
      final routeRef = FirebaseFirestore.instance
          .collection('busRoutes')
          .doc(widget.busRouteId);

      // Crear mapa de actualización para los asientos
      final seatsUpdate = {
        for (var boleto in widget.boletos)
          'seats.${boleto.asiento}': true // Marcar asientos como ocupados
      };

      batch.update(routeRef, seatsUpdate);

      await batch.commit();
      widget.onTicketPurchased();

      if (mounted) {
        setState(() {
          _comprado = true;
          _guardando = false;
        });
        await _generarImagenTicket();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _boletosIds = [];
          _shouldRefresh = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al comprar: $e')),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _generarImagenTicket() async {
    try {
      final boundary = _ticketKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      setState(() => _ticketImage = pngBytes);
    } catch (e) {
      debugPrint("Error al generar imagen del ticket: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al generar imagen del boleto')),
      );
    }
  }
}
