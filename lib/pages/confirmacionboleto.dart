import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../models/boleto.dart';

class ConfirmacionBoletoScreen extends StatefulWidget {
  final Boleto boleto;

  const ConfirmacionBoletoScreen({super.key, required this.boleto});
  @override
  State<ConfirmacionBoletoScreen> createState() => _ConfirmacionBoletoScreenState();
}

class _ConfirmacionBoletoScreenState extends State<ConfirmacionBoletoScreen> {
  bool _formatoListo = false;

  @override
  void initState() {
    super.initState();
    _inicializarFormatoFecha();
  }

  Future<void> _inicializarFormatoFecha() async {
    await initializeDateFormatting('es_MX', null);
    setState(() {
      _formatoListo = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación')),
      body: Center(
        child: Text('Asiento: ${widget.boleto.asiento}, Ruta: ${widget.boleto.ruta}'),
      ),
    );

  }
}
