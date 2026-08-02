import 'src/android/android_contacts_platform.dart';
import 'src/platform/contacts_platform.dart';

/// Android registration entrypoint for `flutter_contacts_pro`.
///
/// Call once at app startup on Android before using
/// [FlutterContactsPro.instance]:
///
/// ```dart
/// import 'package:flutter_contacts_pro/android.dart';
///
/// void main() {
///   FlutterContactsProAndroid.register();
///   runApp(const MyApp());
/// }
/// ```
abstract final class FlutterContactsProAndroid {
  FlutterContactsProAndroid._();

  /// Installs the JNIGEN-backed [AndroidContactsPlatform].
  static void register() {
    ContactsPlatform.instance = AndroidContactsPlatform();
  }
}
