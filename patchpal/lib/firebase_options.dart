// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC6OEaB5c-Lm-Yysvf0QlscHRzzZgyD_kY',
    appId: '1:680208024985:android:a857690d68a9037214ff08',
    messagingSenderId: '680208024985',
    projectId: 'patchpal-e9dcf',
    storageBucket: 'patchpal-e9dcf.firebasestorage.app',
  );
  
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAtrwHGhNEZdG15qXjt0Q2__jOmGUhzojk',
    appId: '1:680208024985:ios:a42d08c5ef3d2b6814ff08',
    messagingSenderId: '680208024985', 
    projectId: 'patchpal-e9dcf',
    storageBucket: 'patchpal-e9dcf.firebasestorage.app',
    iosBundleId: 'com.bright.patchpal',
  );
}