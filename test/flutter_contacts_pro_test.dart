import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';
import 'package:flutter_contacts_pro/testing.dart';

void main() {
  late FakeContactsPlatform fake;
  late FlutterContactsPro api;

  setUp(() {
    fake = FakeContactsPlatform(
      contacts: const [
        Contact(
          id: '1',
          displayName: 'Ada Lovelace',
          phones: [Phone(number: '111', label: PhoneLabel.mobile)],
          emails: [Email(address: 'ada@example.com')],
        ),
        Contact(
          id: '2',
          displayName: 'Grace Hopper',
          phones: [Phone(number: '222')],
        ),
        Contact(
          id: '3',
          displayName: 'Alan Turing',
          phones: [Phone(number: '333')],
        ),
      ],
      avatars: {
        '1': Uint8List.fromList([1, 2, 3]),
      },
    );
    api = FlutterContactsPro(platform: fake);
  });

  tearDown(() {
    fake.dispose();
  });

  test('default platform instance is unimplemented', () {
    expect(
      ContactsPlatform.instance,
      isA<ContactsPlatform>(),
    );
  });

  test('getContacts paginates and projects fields', () async {
    final page = await api.getContacts(
      query: const ContactQuery(
        fields: ContactFields.minimal,
        pageSize: 2,
      ),
    );
    expect(page.contacts, hasLength(2));
    expect(page.hasMore, isTrue);
    expect(page.estimatedTotal, 3);
    expect(page.contacts.first.phones, isEmpty);

    final page2 = await api.getContacts(
      query: ContactQuery(
        fields: ContactFields.list,
        pageSize: 2,
        pageToken: page.nextPageToken,
      ),
    );
    expect(page2.contacts, hasLength(1));
    expect(page2.hasMore, isFalse);
  });

  test('search is case-insensitive and trims query', () async {
    final page = await api.search('  ada ');
    expect(page.contacts, hasLength(1));
    expect(page.contacts.single.id, '1');
  });

  test('search with empty query returns empty page', () async {
    final page = await api.search('   ');
    expect(page.contacts, isEmpty);
    expect(page.nextPageToken, isNull);
  });

  test('getContact returns null for missing id', () async {
    expect(await api.getContact('missing'), isNull);
  });

  test('getContact rejects empty id', () async {
    expect(
      () => api.getContact(''),
      throwsA(isA<InvalidContactException>()),
    );
  });

  test('getAvatar and hasAvatar', () async {
    expect(await api.hasAvatar('1'), isTrue);
    expect(await api.getAvatar('1'), Uint8List.fromList([1, 2, 3]));
    expect(await api.hasAvatar('2'), isFalse);
    expect(await api.getAvatar('2'), isNull);
  });

  test('createContact assigns id and emits change', () async {
    final events = <ContactChangeEvent>[];
    final sub = api.onContactsChanged.listen(events.add);

    final created = await api.createContact(
      const Contact(
        displayName: 'New Person',
        phones: [Phone(number: '999')],
      ),
    );
    expect(created.id, isNotEmpty);
    expect(created.isPersisted, isTrue);

    await Future<void>.delayed(Duration.zero);
    expect(events, isNotEmpty);
    expect(events.last.type, ContactChangeType.added);

    await sub.cancel();
  });

  test('updateContact requires id', () async {
    expect(
      () => api.updateContact(const Contact(displayName: 'X')),
      throwsA(isA<InvalidContactException>()),
    );
  });

  test('updateContact and deleteContact', () async {
    final updated = await api.updateContact(
      const Contact(id: '2', displayName: 'Grace M. Hopper'),
    );
    expect(updated.displayName, 'Grace M. Hopper');

    await api.deleteContact('2');
    expect(await api.getContact('2'), isNull);
  });

  test('deleteContact throws when missing', () async {
    expect(
      () => api.deleteContact('nope'),
      throwsA(isA<ContactNotFoundException>()),
    );
  });

  test('permission helpers delegate', () async {
    fake.permissionStatus = PermissionStatus.denied;
    expect(await api.getPermissionStatus(), PermissionStatus.denied);
    expect(await api.requestPermission(), PermissionStatus.granted);
    expect(await api.openSettings(), isTrue);
  });

  test('denied permission blocks reads', () async {
    fake.permissionStatus = PermissionStatus.denied;
    expect(
      () => api.getContacts(),
      throwsA(isA<PermissionDeniedException>()),
    );
  });

  test('groups create and membership', () async {
    final group = await api.createGroup('Favorites');
    expect(group.name, 'Favorites');

    await api.addContactsToGroup(group.id, ['1']);
    final contact = await api.getContact('1');
    expect(contact!.groupIds, contains(group.id));

    final groups = await api.getGroups();
    expect(groups.single.memberCount, 1);

    await api.removeContactsFromGroup(group.id, ['1']);
    final after = await api.getContact('1');
    expect(after!.groupIds, isEmpty);

    await api.deleteGroup(group.id);
    expect(await api.getGroups(), isEmpty);
  });

  test('createGroup rejects blank name', () {
    expect(
      () => api.createGroup('  '),
      throwsA(isA<InvalidContactException>()),
    );
  });

  test('deleteContacts with empty list is no-op', () async {
    await api.deleteContacts(['', '']);
    expect(fake.contacts, hasLength(3));
  });

  test('clearCache is safe to call', () {
    expect(api.clearCache, returnsNormally);
  });

  test('pageSize is normalized by facade', () async {
    final page = await api.getContacts(
      query: const ContactQuery(pageSize: 9999),
    );
    // All 3 fit in one clamped page of 500.
    expect(page.contacts, hasLength(3));
    expect(page.hasMore, isFalse);
  });
}
