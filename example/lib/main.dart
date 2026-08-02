import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_contacts_pro/android.dart';

import 'app.dart';

export 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    FlutterContactsProAndroid.register();
  }
  runApp(const MyApp());
}
