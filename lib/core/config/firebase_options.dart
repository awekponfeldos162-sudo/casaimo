import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ne supporte pas cette plateforme.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB7oIdVUTMxa4WDI1EfGACv9swhUKcPMj8',
    appId: '1:710396968816:web:0a3528407889541969d9b5',
    messagingSenderId: '710396968816',
    projectId: 'casaimo',
    authDomain: 'casaimo.firebaseapp.com',
    storageBucket: 'casaimo.firebasestorage.app',
    measurementId: 'G-T740TEBJDS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2RP3Al_VUfTSA3o-sTG1D9orH3bN2RKo',
    appId: '1:710396968816:android:4c87cd438cf34ade69d9b5',
    messagingSenderId: '710396968816',
    projectId: 'casaimo',
    storageBucket: 'casaimo.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBN_yW4hR_rm-50nbcpO4AmNKk4mdkE2u8',
    appId: '1:710396968816:ios:d275fdbf310730a069d9b5',
    messagingSenderId: '710396968816',
    projectId: 'casaimo',
    storageBucket: 'casaimo.firebasestorage.app',
    iosBundleId: 'com.casaimo.casaimo',
  );
}
