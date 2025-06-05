import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream
      .throttleTime(const Duration(milliseconds: 500))
      .listen((scanData) {
        if (scanData.code != null && !_isProcessing) {
          _validateTicket(scanData.code!);
        }
      });
  }

  Future<void> _validateTicket(String qrData) async {
    setState(() => _isProcessing = true);
    
    try {
      final ticketId = qrData.replaceFirst('boleto_', '');
      final ticketRef = _firestore.collection('Boletos').doc(ticketId);
      final doc = await ticketRef.get();

      if (!doc.exists) {
        _showResultDialog('Boleto no válido', 'El boleto no existe en el sistema');
        return;
      }

      final ticketData = doc.data() as Map<String, dynamic>;

      if (ticketData['rutald'] != 'mvwEOur0XoEd0PRD6Olv') {
        _showResultDialog('Boleto incorrecto', 'Este boleto no es para esta ruta');
        return;
      }

      if (ticketData['estado'] != 'activo') {
        _showResultDialog('Boleto usado', 'Este boleto ya fue utilizado');
        return;
      }

      final now = DateTime.now();
      final ticketDate = (ticketData['fecha'] as Timestamp).toDate();
      
      if (!_isSameDay(ticketDate, now)) {
        _showResultDialog('Boleto vencido', 'La fecha del boleto no es válida');
        return;
      }

      await ticketRef.update({
        'estado': 'usado',
        'fechaUso': FieldValue.serverTimestamp(),
        'conductorId': _auth.currentUser?.uid,
      });

      _showResultDialog('Boleto válido', 'Asiento: ${ticketData['asiento']}\nPrecio: \$${ticketData['precio']}');
    } catch (e) {
      _showResultDialog('Error', 'Ocurrió un error al validar el boleto: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller?.resumeCamera();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código QR'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              formatsAllowed: const [BarcodeFormat.qrcode],
              overlay: QrScannerOverlayShape(
                borderColor: Colors.green,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),

        ],
      ),
    );
  }
}