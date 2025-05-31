import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:nau/models/user.dart';
import 'package:nau/services/auth/auth_services.dart';

import 'dart:io';

import 'package:nau/services/auth/database/database_provider.dart';
import 'package:provider/provider.dart';

import '../components/my_settings_tile.dart';

class PerfilConfig extends StatefulWidget {
  final String userId;
  const PerfilConfig({super.key, required this.userId});

  @override
  PerfilConfigState createState() => PerfilConfigState();
}

class PerfilConfigState extends State<PerfilConfig> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String? _imageUrl;
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _birthDateController = TextEditingController();

  bool _hasUnsavedChanges = false;

  UserProfile? userData;

  late final databaseProvider =
      Provider.of<DatabaseProvider>(context, listen: false);

  //loading...
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recorta tu foto',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Recorta tu foto',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _imageFile = XFile(croppedFile.path);
          _hasUnsavedChanges = true;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    try {
      // Primero sube la imagen si hay alguna seleccionada
      if (_imageFile != null) {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('$userId.jpg');

        await ref.putFile(File(_imageFile!.path));
        final url = await ref.getDownloadURL();
        setState(() {
          _imageUrl = url;
        });
      }

      // Construye los datos a actualizar incluyendo la URL de la imagen si existe
      final updatedData = {
        'name': _nameController.text,
        'lastName': _lastNameController.text,
        'phoneNumber': _phoneNumberController.text,
      };

      if (_imageUrl != null) {
        updatedData['profilePic'] = _imageUrl!;
      }

      // Actualiza el perfil en Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Perfil actualizado con éxito'),
      ));
      setState(() {
        _hasUnsavedChanges = false;
      });

      Navigator.pop(context, true); // <-- ESTA línea permite volver y recargar
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al actualizar el perfil'),
      ));
    }
  }

  Future<void> _loadUserData() async {
    try {
      //obtener informacion del usuario
      userData = await databaseProvider.userProfile(widget.userId);
      //finalizar la carga
      setState(() {
        _isLoading = false;
      });

      if (userData != null) {
        if (!mounted) return;

        setState(() {
          _nameController.text = userData!.name;
          _lastNameController.text = userData!.lastName;
          _phoneNumberController.text = userData!.phoneNumber;
          _birthDateController.text = userData?.birthDate != null
              ? (userData!.birthDate).toDate().toString().split(' ')[0]
              : '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar los datos: $e')),
      );
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
          title: const Text('Editar perfil'),
          foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: RefreshIndicator(
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Importante para permitir el gesto de deslizamiento y actualizar
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : userData != null
                    ? Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Parte superior del perfil
                            Row(
                              children: [
                                // Foto de perfil redonda (más grande)
                                _imageFile != null
                                    ? ClipOval(
                                        child: Image.file(
                                          File(_imageFile!.path),
                                          width: 150,
                                          height: 150,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : (userData != null &&
                                            (userData?.profilePic ?? '') != '')
                                        ? ClipOval(
                                            child: Image.network(
                                              userData?.profilePic ?? '',
                                              width: 150,
                                              height: 150,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const CircleAvatar(
                                            radius: 80,
                                            backgroundColor: Colors.grey,
                                            child: Icon(Icons.person, size: 80),
                                          ),
                                const SizedBox(width: 20),
                                // Nickname y nombre
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '@${userData?.username ?? 'usuario'}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                        ),
                                      ),
                                      Text(
                                        userData?.name ??
                                            'Nombre real',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inverseSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    builder: (BuildContext context) {
                                      return SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: Text(
                                                'Cambiar foto del perfil',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                  Icons.photo_library),
                                              title: const Text('Subir foto'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickImage();
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.delete),
                                              title: const Text(
                                                'Eliminar foto actual',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                              onTap: () async {
                                                Navigator.pop(context);
                                                await FirebaseFirestore.instance
                                                    .collection('Users')
                                                    .doc(widget.userId)
                                                    .update({'profilePic': ''});
                                                setState(() async {
                                                  _imageFile = null;
                                                  _imageUrl = null;
                                                  _hasUnsavedChanges = true;
                                                  await _loadUserData();
                                                });
                                              },
                                            ),
                                            const Divider(),
                                            ListTile(
                                              title: const Center(
                                                  child: Text('Cancelar')),
                                              onTap: () {
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: const Text('Cambiar foto'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Campo de nombre de usuario
                            TextField(
                              controller: _nameController,
                              decoration:
                                  const InputDecoration(labelText: 'Nombre'),
                              onChanged: (_) => _hasUnsavedChanges = true,
                            ),
                            const SizedBox(height: 10),
                            // Campo de Apellidos
                            TextField(
                              controller: _lastNameController,
                              decoration:
                                  const InputDecoration(labelText: 'Apellidos'),
                              onChanged: (_) => _hasUnsavedChanges = true,
                            ),
                            const SizedBox(height: 20),
                            // Campo de número de teléfono
                            TextField(
                              controller: _phoneNumberController,
                              decoration: const InputDecoration(
                                  labelText: ' Numero de telefono'),
                              onChanged: (_) => _hasUnsavedChanges = true,
                            ),
                            const SizedBox(height: 20),
                            // Campo de fecha de nacimiento
                            TextField(
                              controller: _birthDateController,
                              decoration: const InputDecoration(
                                  labelText: ' Fecha de nacimiento'),
                              enabled: false,
                            ),
                            const SizedBox(height: 20),
                            // Botón para guardar cambios
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                              onPressed: _updateProfile,
                              child: const Text('Guardar cambios'),
                            ),
                            const SizedBox(height: 20),
                            // Botón para eliminar cuenta
                            MySettingsTile(
                              title: "Eliminar cuenta",
                              action: IconButton(
                                icon: const Icon(Icons.delete_forever,
                                    color: Colors.red),
                                onPressed: () async {
                                  final authService = Provider.of<AuthService>(
                                      context,
                                      listen: false);

                                  // Opcional: mostrar un diálogo de confirmación
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('¿Eliminar cuenta?'),
                                      content: const Text(
                                          'Esta acción no se puede deshacer. ¿Seguro que quieres eliminar tu cuenta?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Eliminar',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await authService.deleteAccount();
                                      if (!context.mounted) return;
                                      // Cierra todas las rutas y navega al login
                                      Navigator.of(context)
                                          .pushNamedAndRemoveUntil(
                                        '/login',
                                        (Route<dynamic> route) => false,
                                      );
                                    } catch (e) {
                                      // Muestra un mensaje de error si ocurre algo
                                      if (context.mounted) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Error'),
                                            content: Text(e.toString()),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Center(
                        child: Text(
                            'No se pudo cargar la información del usuario'),
                      ),
          ),
        ),
      ),
    );
  }
}
