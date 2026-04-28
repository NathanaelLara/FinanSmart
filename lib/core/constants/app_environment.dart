import 'package:firebase_core/firebase_core.dart';

class AppEnvironment {
  const AppEnvironment._();

  static const bool useFirebase = true;

  static bool get isFirebaseReady {
    if (!useFirebase) {
      return false;
    }

    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
