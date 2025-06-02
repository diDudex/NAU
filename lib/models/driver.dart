// models/driver.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DriverProfile {
  final String uid;
  final String name;
  final String lastName;
  final String email;

  final String profilePic;

  DriverProfile({
    required this.uid,
    required this.name,
    required this.lastName,
    required this.email,
    required this.profilePic,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'lastName': lastName,
      'email': email,
      'profilePic': profilePic,
    };
  }

  factory DriverProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DriverProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      profilePic: data['profilePic'] ?? '',
    );
  }
}
