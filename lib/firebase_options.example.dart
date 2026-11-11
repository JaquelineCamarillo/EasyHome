// ARCHIVO DE EJEMPLO PARA CONFIGURACIÓN DE FIREBASE (VALORES FICTICIOS)
// Copia este archivo a 'lib/firebase_options.dart' y reemplaza con las credenciales
// de tu propio proyecto de Firebase o ejecuta: `flutterfire configure`.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] para usar con la app EasyHome.
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
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSy_TU_API_KEY_WEB_AQUI',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'easyhome-ejemplo',
    authDomain: 'easyhome-ejemplo.firebaseapp.com',
    storageBucket: 'easyhome-ejemplo.firebasestorage.app',
    measurementId: 'G-XXXXXXXXXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy_TU_API_KEY_ANDROID_AQUI',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'easyhome-ejemplo',
    storageBucket: 'easyhome-ejemplo.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy_TU_API_KEY_IOS_AQUI',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'easyhome-ejemplo',
    storageBucket: 'easyhome-ejemplo.firebasestorage.app',
    iosBundleId: 'com.example.easyhome',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSy_TU_API_KEY_MACOS_AQUI',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'easyhome-ejemplo',
    storageBucket: 'easyhome-ejemplo.firebasestorage.app',
    iosBundleId: 'com.example.easyhome',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSy_TU_API_KEY_WINDOWS_AQUI',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'easyhome-ejemplo',
    authDomain: 'easyhome-ejemplo.firebaseapp.com',
    storageBucket: 'easyhome-ejemplo.firebasestorage.app',
    measurementId: 'G-XXXXXXXXXX',
  );
}
