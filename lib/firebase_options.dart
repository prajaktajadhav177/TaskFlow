import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyASa6V0XHoz3oQc7eupFhv_qgzF4Ml5RKo',
    appId: '1:697456266231:web:7ce47d9782ca3ef0ccbcf2',
    messagingSenderId: '697456266231',
    projectId: 'task-manager-prajakta',
    authDomain: 'task-manager-prajakta.firebaseapp.com',
    storageBucket: 'task-manager-prajakta.firebasestorage.app',
    measurementId: 'G-HSL3ZZZ6GK',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyASa6V0XHoz3oQc7eupFhv_qgzF4Ml5RKo',
    appId: '1:697456266231:android:placeholder',
    messagingSenderId: '697456266231',
    projectId: 'task-manager-prajakta',
    storageBucket: 'task-manager-prajakta.firebasestorage.app',
  );
}