import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nau/controller/perfil_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:nau/services/auth/auth_services.dart';
import 'package:nau/services/auth/database/database_provider.dart';
import 'package:nau/components/my_settings_tile.dart';

class PerfilConfig extends StatefulWidget {
  final String userId;
  const PerfilConfig({super.key, required this.userId});

  @override
  PerfilConfigState createState() => PerfilConfigState();
}

class PerfilConfigState extends State<PerfilConfig> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerfilViewModel(
        databaseProvider: Provider.of<DatabaseProvider>(context, listen: false),
        userId: widget.userId,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar perfil'),
          foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Consumer<PerfilViewModel>(
          builder: (context, viewModel, child) {
            return WillPopScope(
              onWillPop: () async {
                if (!viewModel.hasUnsavedChanges) return true;
                
                final shouldLeave = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cambios no guardados'),
                    content: const Text(
                        'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir sin guardar?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Salir'),
                      ),
                    ],
                  ),
                );
                return shouldLeave ?? false;
              },
              child: _buildBody(context, viewModel),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PerfilViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.userProfile == null) {
      return const Center(
        child: Text('No se pudo cargar la información del usuario'),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(context, viewModel),
              const SizedBox(height: 20),
              _buildChangePhotoButton(context, viewModel),
              const SizedBox(height: 20),
              _buildProfileForm(viewModel),
              const SizedBox(height: 20),
              _buildSaveButton(viewModel),
              const SizedBox(height: 20),
              _buildDeleteAccountButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, PerfilViewModel viewModel) {
    return Row(
      children: [
        // Foto de perfil
        ClipOval(
          child: viewModel.imageFile != null
              ? Image.file(
                  File(viewModel.imageFile!.path),
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                )
              : (viewModel.userProfile?.profilePic ?? '').isNotEmpty
                  ? Image.network(
                      viewModel.userProfile!.profilePic,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  : const CircleAvatar(
                      radius: 75,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 80),
                    ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${viewModel.userProfile?.username ?? 'usuario'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              Text(
                viewModel.userProfile?.name ?? 'Nombre real',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.inverseSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChangePhotoButton(BuildContext context, PerfilViewModel viewModel) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: () => _showImagePickerModal(context, viewModel),
        child: const Text('Cambiar foto'),
      ),
    );
  }

  void _showImagePickerModal(BuildContext context, PerfilViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Subir foto'),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Eliminar foto actual',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.deleteProfileImage();
                },
              ),
              const Divider(),
              ListTile(
                title: const Center(child: Text('Cancelar')),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileForm(PerfilViewModel viewModel) {
    return Column(
      children: [
        TextField(
          controller: viewModel.nameController,
          decoration: const InputDecoration(labelText: 'Nombre'),
          onChanged: (_) => viewModel.onFieldChanged(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: viewModel.lastNameController,
          decoration: const InputDecoration(labelText: 'Apellidos'),
          onChanged: (_) => viewModel.onFieldChanged(),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: viewModel.phoneNumberController,
          decoration: const InputDecoration(labelText: 'Número de teléfono'),
          onChanged: (_) => viewModel.onFieldChanged(),
        ),
      ],
    );
  }

  Widget _buildSaveButton(PerfilViewModel viewModel) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: viewModel.isUpdating ? null : () async {
        await viewModel.updateProfile();
        if (viewModel.error == ProfileError.none) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado con éxito')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar el perfil')),
          );
        }
      },
      child: viewModel.isUpdating
          ? const CircularProgressIndicator()
          : const Text('Guardar cambios'),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return MySettingsTile(
      title: "Eliminar cuenta",
      action: IconButton(
        icon: const Icon(Icons.delete_forever, color: Colors.red),
        onPressed: () => _confirmDeleteAccount(context),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: const Text(
            'Esta acción no se puede deshacer. ¿Seguro que quieres eliminar tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        await authService.deleteAccount();
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('No se pudo eliminar la cuenta: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}