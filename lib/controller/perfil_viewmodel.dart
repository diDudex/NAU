import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:nau/models/user.dart';
import 'package:nau/services/auth/database/database_provider.dart';

enum ProfileError {
  loadFailed,
  updateFailed,
  imageUploadFailed,
  deleteFailed,
  none
}

class PerfilViewModel extends ChangeNotifier {
  final DatabaseProvider databaseProvider;
  final String userId;

  XFile? _imageFile;
  String? _imageUrl;
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  bool _isLoading = true;
  bool _isUpdating = false;
  ProfileError _error = ProfileError.none;
  UserProfile? userData;
  bool _hasUnsavedChanges = false;

  PerfilViewModel({required this.databaseProvider, required this.userId}) {
    loadUserData();
  }

  // Getters
  XFile? get imageFile => _imageFile;
  String? get imageUrl => _imageUrl;
  TextEditingController get nameController => _nameController;
  TextEditingController get lastNameController => _lastNameController;
  TextEditingController get phoneNumberController => _phoneNumberController;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  ProfileError get error => _error;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  UserProfile? get userProfile => userData;

  Future<void> loadUserData() async {
    try {
      userData = await databaseProvider.userProfile(userId);
      _error = ProfileError.none;

      if (userData != null) {
        _nameController.text = userData!.name;
        _lastNameController.text = userData!.lastName;
        _phoneNumberController.text = userData!.phoneNumber;
      }
    } catch (e) {
      _error = ProfileError.loadFailed;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

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
        _imageFile = XFile(croppedFile.path);
        _hasUnsavedChanges = true;
        notifyListeners();
      }
    } catch (e) {
      _error = ProfileError.imageUploadFailed;
      notifyListeners();
    }
  }

  Future<void> updateProfile() async {
    _isUpdating = true;
    _error = ProfileError.none;
    notifyListeners();

    try {
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('$userId.jpg');

        await ref.putFile(File(_imageFile!.path));
        _imageUrl = await ref.getDownloadURL();
      }

      final updatedData = {
        'name': _nameController.text,
        'lastName': _lastNameController.text,
        'phoneNumber': _phoneNumberController.text,
        if (_imageUrl != null) 'profilePic': _imageUrl!,
      };

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .update(updatedData);

      _hasUnsavedChanges = false;
    } catch (e) {
      _error = ProfileError.updateFailed;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> deleteProfileImage() async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .update({'profilePic': ''});

      _imageFile = null;
      _imageUrl = null;
      _hasUnsavedChanges = true;
      await loadUserData();
    } catch (e) {
      _error = ProfileError.deleteFailed;
      notifyListeners();
    }
  }

  void onFieldChanged() {
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }
}
