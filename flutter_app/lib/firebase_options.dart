// PLACEHOLDER — this file is normally generated for you.
//
// Run `flutterfire configure` (see BUILD-ANDROID.md) and it will OVERWRITE
// this file with your real project's values and wire up Android. Until then
// the app builds but shows a "Firebase not configured" screen at launch.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Run the FlutterFire CLI again (flutterfire configure).',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    authDomain: 'REPLACE_ME.firebaseapp.com',
    storageBucket: 'REPLACE_ME.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCMfZTsWugARq5PtJfaLu_gzHpbA0Q6DO8',
    appId: '1:765758847064:android:8b36c0d82899f26a30322d',
    messagingSenderId: '765758847064',
    projectId: 'family-expenses-2b31c',
    storageBucket: 'family-expenses-2b31c.firebasestorage.app',
  );
}
