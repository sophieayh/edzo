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
    apiKey: 'AIzaSyAUEqgJ0VDGlhLvpLd2PJHTYOYFRte2oL4',
    appId: '1:539354285069:android:282677ea505c0289420144',
    messagingSenderId: '539354285069',
    projectId: 'coursberry',
    storageBucket: 'coursberry.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCvC8JKOOaHIGTMFBpwbyLrDjfrMRqXqx4',
    appId: '1:539354285069:ios:06ac17dce82841ef420144',
    messagingSenderId: '539354285069',
    projectId: 'coursberry',
    storageBucket: 'coursberry.appspot.com',
    androidClientId: '539354285069-n2b1pcmerjaa583tg1d170s79kjs0ede.apps.googleusercontent.com',
    iosClientId: '539354285069-sk7tvl6kotmj5g1opuo2d3tp02ciagko.apps.googleusercontent.com',
    iosBundleId: 'com.example.finaloneCourses',
  );

}