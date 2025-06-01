import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

abstract class ProfileRepository {
  Future<void> updateProfile(String userId, Map<String, dynamic> data);
  Future<String> uploadProfileImage(String userId, File image);
  Future<void> deleteProfileImage(String userId);
}

class FirebaseProfileRepository implements ProfileRepository {
  @override
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .update(data);
  }

  @override
  Future<String> uploadProfileImage(String userId, File image) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('$userId.jpg');
    
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  @override
  Future<void> deleteProfileImage(String userId) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .update({'profilePic': ''});
  }
}