import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';
import 'package:flutter_contacts_pro/testing.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fake platform getContacts smoke test', (WidgetTester tester) async {
    final fake = FakeContactsPlatform(
      contacts: const [
        Contact(id: '1', displayName: 'Ada'),
      ],
    );
    final api = FlutterContactsPro(platform: fake);

    final page = await api.getContacts();
    expect(page.contacts, hasLength(1));
    expect(page.contacts.single.displayName, 'Ada');

    fake.dispose();
  });
}
