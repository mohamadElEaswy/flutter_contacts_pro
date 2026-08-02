import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';
import 'package:flutter_contacts_pro/testing.dart';

import 'package:flutter_contacts_pro_example/main.dart';

void main() {
  testWidgets('Shows contacts status', (WidgetTester tester) async {
    final fake = FakeContactsPlatform(
      contacts: const [
        Contact(id: '1', displayName: 'Ada Lovelace'),
        Contact(id: '2', displayName: 'Grace Hopper'),
      ],
    );
    addTearDown(fake.dispose);

    await tester.pumpWidget(
      MyApp(api: FlutterContactsPro(platform: fake)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Showing 2 of ~2'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('Filters contacts with search', (WidgetTester tester) async {
    final fake = FakeContactsPlatform(
      contacts: const [
        Contact(id: '1', displayName: 'Ada Lovelace'),
        Contact(id: '2', displayName: 'Grace Hopper'),
      ],
    );
    addTearDown(fake.dispose);

    await tester.pumpWidget(
      MyApp(api: FlutterContactsPro(platform: fake)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(SearchBar), 'Grace');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsNothing);
    expect(find.textContaining('matches'), findsOneWidget);
  });
}
