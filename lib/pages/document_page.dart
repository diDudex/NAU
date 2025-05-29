import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:nau/models/documents.dart';
import 'package:intl/intl.dart';
import 'package:nau/services/auth/database/database_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

class DocumentPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const DocumentPage({super.key, required this.userId, required this.userData});

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  UserDocument? _userDocument;

  File? _selectedFile;
  bool _hasUnsavedChanges = false;

  String? _selectedDocType;
  final List<String> _docTypes = [
    'Estudiante',
    'Jubilado/Pensionado',
    'Discapacidad',
    'Otro',
  ];

  final DatabaseProvider _db = DatabaseProvider();

  @override
  void initState() {
    super.initState();
    _loadUserDocument();
  }

  Future<void> _loadUserDocument() async {
    setState(() => _userDocument = null);

    try {
      final doc = await _db.getDoc(widget.userId);
      setState(
        () => _userDocument = doc,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando documento: $e')),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    await _handlePickedFile(pickedFile);
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    await _handlePickedFile(pickedFile);
  }

  Future<void> _handlePickedFile(XFile? pickedFile) async {
    if (pickedFile == null) return;

    final archivo = await FlutterImageCompress.compressAndGetFile(
      pickedFile.path,
      pickedFile.path
          .replaceFirst(RegExp(r'\.(jpg|jpeg|png)$'), '_compressed.jpg'),
      quality: 85,
      minWidth: 1024,
      rotate: 0,
    );

    if (archivo != null) {
      setState(() {
        _selectedFile = File(archivo.path);
        _hasUnsavedChanges = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen comprimida y subida con éxito')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo comprimir la imagen')),
      );
    }
  }

  Future<void> _seleccionarArchivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);

      setState(() {
        _selectedFile = file;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Archivo seleccionado. Presiona "Subir documento".')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se seleccionó ningún archivo')),
      );
    }
  }

  void _showInstructionsBeforePick() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Instrucciones para subir el documento'),
        content: const Text(
          'Por favor, asegúrate de que todo el documento esté visible y legible. '
          'No recortes la imagen, ya que se procesará automáticamente.\n\n'
          'Alinea bien el documento dentro del marco para mejores resultados.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromCamera(); // Abre la cámara después de aceptar las instrucciones
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  String _documentStatusMessage() {
    if (_userDocument == null) {
      return 'No has subido ningún documento para descuento.';
    }

    final status = _userDocument!.status.toLowerCase();

    if (status == 'sin documentos') {
      return 'No has subido ningún documento para descuento.';
    } else if (status == 'pendiente') {
      return 'Tu documento está pendiente de revisión.';
    } else if (status == 'rechazado') {
      return 'Tu documento fue rechazado. Por favor, sube uno nuevo.';
    } else if (status == 'activo') {
      if (_userDocument!.expiryDate.toDate().isBefore(DateTime.now())) {
        return 'Tu documento ha expirado. Por favor, sube uno nuevo.';
      }

      final expiryStr = DateFormat('dd/MM/yyyy').format(
        _userDocument!.expiryDate.toDate(),
      );
      return 'Tu documento está activo hasta el $expiryStr.';
    }

    return 'Estado desconocido del documento.';
  }

  void _mostrarMenuSeleccion() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar foto del documento'),
                onTap: () {
                  Navigator.pop(context);
                  _showInstructionsBeforePick(); // Muestra instrucciones y abre cámara
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar imagen de la galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery(); // Abre la galería
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Seleccionar archivo (PDF u otro)'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarArchivo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadFile(File archivo) async {
    if (_selectedDocType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona el tipo de documento antes de subir.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final ext = archivo.path.split('.').last;
      final fileName = 'document_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance
          .ref()
          .child('documents')
          .child(widget.userId)
          .child(fileName);

      await ref.putFile(archivo);
      final url = await ref.getDownloadURL();

      await _db.saveDoc(
        userid: widget.userId,
        fileURL: url,
        status: 'Pendiente',
        expiryDate: DateTime.now(),
        docType: _selectedDocType ?? '',
      );

      final newDoc = UserDocument(
        userid: widget.userId,
        fileURL: url,
        status: 'Pendiente',
        expiryDate: Timestamp.now(),
        docType: _selectedDocType ?? '',
      );

      setState(() {
        _userDocument = newDoc;
        _isUploading = false;
        _selectedFile = null;
        _hasUnsavedChanges = false;
        _selectedDocType = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento subido con éxito')),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir: $e')),
      );
    }
  }

  void _mostrarConfirmacionEliminar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: const Text(
            'Al eliminar el documento se suspenderá la validación del descuento y dejará de estar activo. ¿Quieres continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _eliminarDocumentoSubido();
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarDocumentoSubido() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Elimina el archivo de Firebase Storage si existe
      if (_userDocument != null && _userDocument!.fileURL.isNotEmpty) {
        try {
          final ref =
              FirebaseStorage.instance.refFromURL(_userDocument!.fileURL);
          await ref.delete();
        } catch (e) {
          // Si falla la eliminación en Storage, solo muestra un mensaje pero continúa
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('No se pudo eliminar el archivo de Storage: $e')),
          );
        }
      }

      // Actualiza Firestore para eliminar el documento (limpiar campos)
      await _db.saveDoc(
        userid: widget.userId,
        fileURL: '',
        status: 'sin documentos',
        expiryDate: DateTime.now(),
        docType: '',
      );

      setState(() {
        _userDocument = UserDocument(
          userid: _userDocument!.userid,
          fileURL: '',
          status: 'sin documentos',
          expiryDate: Timestamp.now(),
          docType: '',
        );
        _selectedFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento eliminado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando documento: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cambios no guardados'),
          content: const Text(
              'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir sin guardar?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Salir'),
            ),
          ],
        ),
      );
      return shouldLeave ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Validacion de Descuento'),
          foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: RefreshIndicator(
          onRefresh: _loadUserDocument,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Importante para permitir el gesto de deslizamiento y actualizar
            padding: const EdgeInsets.all(20),
            child: _userDocument == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado actual:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _documentStatusMessage(),
                        style: TextStyle(
                          color: (_userDocument!.status.toLowerCase() ==
                                      'rechazado' ||
                                  _userDocument!.status.toLowerCase() ==
                                      'sin documentos')
                              ? Colors.red
                              : (_userDocument!.status.toLowerCase() ==
                                      'pendiente'
                                  ? Colors.amber
                                  : Colors.green),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Mostrar el tipo de documento
                      Text(
                        'Tipo de documento: ${_userDocument!.docType}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Mostrar el archivo seleccionado
                      if (_selectedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Archivo seleccionado:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Builder(
                                builder: (context) {
                                  final ext = _selectedFile!.path
                                      .split('.')
                                      .last
                                      .toLowerCase();
                                  if ([
                                    'jpg',
                                    'jpeg',
                                    'png',
                                    'gif',
                                    'bmp',
                                    'webp'
                                  ].contains(ext)) {
                                    // Mostrar imagen
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 350,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _selectedFile!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    );
                                  } else if (['pdf', 'doc', 'docx']
                                      .contains(ext)) {
                                    // Mostrar ícono y nombre del archivo
                                    IconData icon;
                                    if (ext == 'pdf') {
                                      icon = Icons.picture_as_pdf;
                                    } else {
                                      icon = Icons.description;
                                    }
                                    return Row(
                                      children: [
                                        Icon(icon,
                                            size: 48, color: Colors.blue),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _selectedFile!.path.split('/').last,
                                            style:
                                                const TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                            icon: const Icon(Icons.open_in_new),
                                            onPressed: () async {
                                              final result =
                                                  await OpenFilex.open(
                                                      _selectedFile!.path);
                                              if (result.type !=
                                                  ResultType.done) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'No se pudo abrir el archivo.')),
                                                );
                                              }
                                            }),
                                      ],
                                    );
                                  } else {
                                    // Otro tipo de archivo
                                    return Row(
                                      children: [
                                        const Icon(Icons.insert_drive_file,
                                            size: 48, color: Colors.grey),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _selectedFile!.path.split('/').last,
                                            style:
                                                const TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 10),
                              // Dropdown para seleccionar el tipo de documento
                              DropdownButtonFormField<String>(
                                value: _selectedDocType,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de documento',
                                  border: OutlineInputBorder(),
                                ),
                                items: _docTypes.map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDocType = value;
                                    _hasUnsavedChanges = true;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              const SizedBox(height: 10),
                              // Aquí agregas el botón para subir imagen
                              ElevatedButton.icon(
                                icon: _isUploading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.upload_file),
                                label: Text(_isUploading
                                    ? 'Subiendo...'
                                    : 'Subir documento'),
                                onPressed: _isUploading || _selectedFile == null
                                    ? null
                                    : () => _uploadFile(_selectedFile!),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Mostrar el documento ya subido (desde Firebase)
                      if (_userDocument!.fileURL.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Documento actual:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () async {
                                final Uri url =
                                    Uri.parse(_userDocument!.fileURL);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url); // sin modo explícito
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No se pudo abrir el documento. Asegúrate de tener un navegador instalado.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                _userDocument!.fileURL,
                                style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      // Botón para eliminar el archivo seleccionado
                      if (_selectedFile != null)
                        ElevatedButton.icon(
                          onPressed: _isUploading
                              ? null
                              : () {
                                  setState(() {
                                    _selectedFile = null;
                                    _selectedDocType = null;
                                    _hasUnsavedChanges = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Archivo seleccionado eliminado')),
                                  );
                                },
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                          label: const Text('Eliminar archivo seleccionado'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      const SizedBox(height: 10),
                      // Eliminar documento ya subido (desde Firebase)
                      if (_userDocument != null &&
                          _userDocument!.fileURL.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: _isUploading
                              ? null
                              : _mostrarConfirmacionEliminar,
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.white),
                          label: const Text('Eliminar documento subido'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Icon(Icons.upload_file,
                                color: Theme.of(context).colorScheme.onPrimary),
                        label: Text(_isUploading
                            ? 'Subiendo...'
                            : 'Selecionar nuevo documento'),
                        onPressed: _isUploading ? null : _mostrarMenuSeleccion,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor:
                              Theme.of(context).colorScheme.inversePrimary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
