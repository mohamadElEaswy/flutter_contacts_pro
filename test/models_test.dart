import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';

void main() {
  group('Contact', () {
    test('isPersisted is false for empty id', () {
      const contact = Contact(displayName: 'Ada');
      expect(contact.isPersisted, isFalse);
    });

    test('copyWith preserves unspecified fields', () {
      const original = Contact(
        id: '1',
        displayName: 'Ada',
        phones: [Phone(number: '123', label: PhoneLabel.mobile)],
        isFavorite: true,
      );
      final updated = original.copyWith(displayName: 'Ada Lovelace');
      expect(updated.id, '1');
      expect(updated.displayName, 'Ada Lovelace');
      expect(updated.phones, original.phones);
      expect(updated.isFavorite, isTrue);
    });

    test('equality compares list fields', () {
      const a = Contact(
        id: '1',
        phones: [Phone(number: '1')],
      );
      const b = Contact(
        id: '1',
        phones: [Phone(number: '1')],
      );
      const c = Contact(
        id: '1',
        phones: [Phone(number: '2')],
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('ContactFields', () {
    test('presets contain expected fields', () {
      expect(ContactFields.minimal, contains(ContactField.id));
      expect(ContactFields.minimal, contains(ContactField.displayName));
      expect(ContactFields.list, containsAll(ContactFields.minimal));
      expect(ContactFields.list, contains(ContactField.phones));
      expect(ContactFields.detail.length, ContactField.values.length);
    });
  });

  group('ContactQuery', () {
    test('defaults', () {
      const query = ContactQuery();
      expect(query.fields, ContactFields.list);
      expect(query.pageSize, kDefaultContactPageSize);
      expect(query.pageToken, isNull);
      expect(query.sort, ContactSort.displayNameAsc);
    });

    test('normalized clamps pageSize', () {
      const tooLarge = ContactQuery(pageSize: 10_000);
      expect(tooLarge.normalized().pageSize, kMaxContactPageSize);

      const tooSmall = ContactQuery(pageSize: 0);
      expect(tooSmall.normalized().pageSize, 1);
    });

    test('copyWith can clear pageToken', () {
      const query = ContactQuery(pageToken: '50');
      expect(query.copyWith(clearPageToken: true).pageToken, isNull);
    });
  });

  group('ContactPage', () {
    test('hasMore reflects nextPageToken', () {
      expect(const ContactPage(contacts: []).hasMore, isFalse);
      expect(
        const ContactPage(contacts: [], nextPageToken: '10').hasMore,
        isTrue,
      );
    });
  });

  group('ContactsException', () {
    test('ContactNotFoundException formats message', () {
      const e = ContactNotFoundException('abc');
      expect(e.contactId, 'abc');
      expect(e.toString(), contains('abc'));
    });

    test('PlatformContactsException includes code', () {
      const e = PlatformContactsException('E_IO', 'failed');
      expect(e.toString(), contains('E_IO'));
    });
  });
}
