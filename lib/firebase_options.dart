// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDjrww39j9Uww52cIICaGO1KWPjHKh5Umg',
    appId: '1:721708979179:web:0dee9e4c1f412e8baebfae',
    messagingSenderId: '721708979179',
    projectId: 'nocapp-534ac',
    authDomain: 'nocapp-534ac.firebaseapp.com',
    storageBucket: 'nocapp-534ac.firebasestorage.app',
    measurementId: 'G-15XG2BZRH2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBWKXcOFJuIvs7yAUGsHZ8ubr9aq4UmRVY',
    appId: '1:721708979179:android:e61e932fcba26fb0aebfae',
    messagingSenderId: '721708979179',
    projectId: 'nocapp-534ac',
    storageBucket: 'nocapp-534ac.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBpEZ1ffPwAsASy2vQ4lzDo6SrAFQ2LdW0',
    appId: '1:721708979179:ios:a16f727934514a76aebfae',
    messagingSenderId: '721708979179',
    projectId: 'nocapp-534ac',
    storageBucket: 'nocapp-534ac.firebasestorage.app',
    iosBundleId: 'com.example.noc',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBpEZ1ffPwAsASy2vQ4lzDo6SrAFQ2LdW0',
    appId: '1:721708979179:ios:a16f727934514a76aebfae',
    messagingSenderId: '721708979179',
    projectId: 'nocapp-534ac',
    storageBucket: 'nocapp-534ac.firebasestorage.app',
    iosBundleId: 'com.example.noc',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDjrww39j9Uww52cIICaGO1KWPjHKh5Umg',
    appId: '1:721708979179:web:d41ea3584494d8b7aebfae',
    messagingSenderId: '721708979179',
    projectId: 'nocapp-534ac',
    authDomain: 'nocapp-534ac.firebaseapp.com',
    storageBucket: 'nocapp-534ac.firebasestorage.app',
    measurementId: 'G-HVTVX44H2L',
  );
}
