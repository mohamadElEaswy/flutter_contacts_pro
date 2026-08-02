import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_contacts_pro/src/android/android_contact_columns.dart';
import 'package:flutter_contacts_pro/src/android/contact_cursor_mapper.dart';
import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';

void main() {
  const mapper = ContactCursorMapper();

  test('fromContactsRow maps summary fields', () {
    final contact = mapper.fromContactsRow(
      {
        AndroidContactColumns.id: 42,
        AndroidContactColumns.displayName: 'Ada Lovelace',
        AndroidContactColumns.starred: 1,
        AndroidContactColumns.contactLastUpdatedTimestamp: 1_700_000_000_000,
      },
      fields: ContactFields.detail,
    );

    expect(contact.id, '42');
    expect(contact.displayName, 'Ada Lovelace');
    expect(contact.isFavorite, isTrue);
    expect(contact.updatedAt, isNotNull);
  });

  test('mergeDataRows projects phones and emails by field mask', () {
    final base = mapper.fromContactsRow({
      AndroidContactColumns.id: 7,
      AndroidContactColumns.displayName: 'Grace',
    });

    final merged = mapper.mergeDataRows(
      base,
      [
        {
          AndroidContactColumns.mimeType: AndroidContactColumns.mimePhone,
          AndroidContactColumns.data1: '555-0100',
          AndroidContactColumns.data2: 2,
          AndroidContactColumns.isPrimary: 1,
        },
        {
          AndroidContactColumns.mimeType: AndroidContactColumns.mimeEmail,
          AndroidContactColumns.data1: 'grace@example.com',
          AndroidContactColumns.data2: 1,
        },
        {
          AndroidContactColumns.mimeType:
              AndroidContactColumns.mimeStructuredName,
          AndroidContactColumns.data2: 'Grace',
          AndroidContactColumns.data3: 'Hopper',
        },
      ],
      fields: {
        ContactField.id,
        ContactField.displayName,
        ContactField.phones,
        ContactField.name,
      },
    );

    expect(merged.phones, hasLength(1));
    expect(merged.phones.single.number, '555-0100');
    expect(merged.phones.single.label, PhoneLabel.mobile);
    expect(merged.phones.single.isPrimary, isTrue);
    expect(merged.emails, isEmpty); // not in field mask
    expect(merged.name?.givenName, 'Grace');
    expect(merged.name?.familyName, 'Hopper');
  });

  test('mergeDataRows parses birthday event', () {
    final base = const Contact(id: '1');
    final merged = mapper.mergeDataRows(
      base,
      [
        {
          AndroidContactColumns.mimeType: AndroidContactColumns.mimeEvent,
          AndroidContactColumns.data1: '--12-10',
          AndroidContactColumns.data2: 3,
        },
      ],
      fields: {ContactField.events},
    );

    expect(merged.events, hasLength(1));
    expect(merged.events.single.month, 12);
    expect(merged.events.single.day, 10);
    expect(merged.events.single.year, isNull);
    expect(merged.events.single.label, ContactEventLabel.birthday);
  });
}
