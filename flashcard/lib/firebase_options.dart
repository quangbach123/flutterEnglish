// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyC4eeB-hevqi2bge8au2twiyGcrO9pjM2A',
    appId: '1:559640153846:web:63d6d851cbf3f771ec66d7',
    messagingSenderId: '559640153846',
    projectId: 'flutter-eng-177bf',
    authDomain: 'flutter-eng-177bf.firebaseapp.com',
    storageBucket: 'flutter-eng-177bf.appspot.com',
    measurementId: 'G-KP1XBGEKV8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB7_Aep02sthUuYbNMbKiDQu4GcuKNJn30',
    appId: '1:559640153846:android:06e2fedc7427183aec66d7',
    messagingSenderId: '559640153846',
    projectId: 'flutter-eng-177bf',
    storageBucket: 'flutter-eng-177bf.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAbhsUfoSeUn5LAutGXSRKKS8RPBg0asck',
    appId: '1:559640153846:ios:12610ab361f5c74bec66d7',
    messagingSenderId: '559640153846',
    projectId: 'flutter-eng-177bf',
    storageBucket: 'flutter-eng-177bf.appspot.com',
    iosBundleId: 'com.example.flashcard',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAbhsUfoSeUn5LAutGXSRKKS8RPBg0asck',
    appId: '1:559640153846:ios:52239286ce915b38ec66d7',
    messagingSenderId: '559640153846',
    projectId: 'flutter-eng-177bf',
    storageBucket: 'flutter-eng-177bf.appspot.com',
    iosBundleId: 'com.example.flashcard.RunnerTests',
  );
}