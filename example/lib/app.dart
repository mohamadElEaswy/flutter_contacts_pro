import 'package:flutter/material.dart';
import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';

import 'screens/contacts_home_page.dart';
import 'theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.api});

  /// Optional override used by widget tests.
  final FlutterContactsPro? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ContactsHomePage(api: api),
    );
  }
}
