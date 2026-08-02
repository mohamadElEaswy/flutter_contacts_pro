import 'dart:async';
import 'dart:typed_data';

import 'src/errors/contacts_exception.dart';
import 'src/models/avatar_size.dart';
import 'src/models/contact.dart';
import 'src/models/contact_change.dart';
import 'src/models/contact_fields.dart';
import 'src/models/contact_group.dart';
import 'src/models/permission_status.dart';
import 'src/platform/contacts_platform.dart';
import 'src/query/contact_page.dart';
import 'src/query/contact_query.dart';
import 'src/query/contact_sort.dart';

/// In-memory [ContactsPlatform] for unit and widget tests.
///
/// Inject via `FlutterContactsPro(platform: fake)`.
class FakeContactsPlatform extends ContactsPlatform {
  FakeContactsPlatform({
    List<Contact>? contacts,
    List<ContactGroup>? groups,
    this.permissionStatus = PermissionStatus.granted,
    Map<String, Uint8List>? avatars,
  })  : _contacts = {
          for (final c in contacts ?? const <Contact>[]) c.id: c,
        },
        _groups = {
          for (final g in groups ?? const <ContactGroup>[]) g.id: g,
        },
        _avatars = Map<String, Uint8List>.of(avatars ?? const {});

  final Map<String, Contact> _contacts;
  final Map<String, ContactGroup> _groups;
  final Map<String, Uint8List> _avatars;
  final StreamController<ContactChangeEvent> _changes =
      StreamController<ContactChangeEvent>.broadcast();

  int _nextContactId = 1;
  int _nextGroupId = 1;

  /// Current fake permission status.
  PermissionStatus permissionStatus;

  /// Whether [openSettings] should report success.
  bool openSettingsResult = true;

  /// All contacts currently stored.
  List<Contact> get contacts =>
      _contacts.values.toList(growable: false);

  void dispose() {
    _changes.close();
  }

  void emitChange(ContactChangeEvent event) {
    _changes.add(event);
  }

  void _ensurePermission() {
    if (permissionStatus != PermissionStatus.granted &&
        permissionStatus != PermissionStatus.limited) {
      throw PermissionDeniedException(
        'Contacts permission not granted.',
        mode: PermissionMode.read.name,
      );
    }
  }

  @override
  Future<PermissionStatus> getPermissionStatus({
    PermissionMode mode = PermissionMode.read,
  }) async =>
      permissionStatus;

  @override
  Future<PermissionStatus> requestPermission({
    PermissionMode mode = PermissionMode.read,
  }) async {
    if (permissionStatus == PermissionStatus.permanentlyDenied ||
        permissionStatus == PermissionStatus.restricted) {
      return permissionStatus;
    }
    permissionStatus = PermissionStatus.granted;
    return permissionStatus;
  }

  @override
  Future<bool> openSettings() async => openSettingsResult;

  @override
  Future<ContactPage> getContacts(ContactQuery query) async {
    _ensurePermission();
    return _pageFor(_sorted(_contacts.values.toList()), query);
  }

  @override
  Future<ContactPage> search(String query, ContactQuery options) async {
    _ensurePermission();
    final lower = query.toLowerCase();
    final matched = _contacts.values.where((c) {
      final name = (c.displayName ?? '').toLowerCase();
      final phones = c.phones.any((p) => p.number.contains(query));
      final emails =
          c.emails.any((e) => e.address.toLowerCase().contains(lower));
      return name.contains(lower) || phones || emails;
    }).toList();
    return _pageFor(_sorted(matched, options.sort), options);
  }

  @override
  Future<Contact?> getContact(String id, Set<ContactField> fields) async {
    _ensurePermission();
    final contact = _contacts[id];
    if (contact == null) return null;
    return _project(contact, fields);
  }

  @override
  Future<Uint8List?> getAvatar(String id, AvatarSize size) async {
    _ensurePermission();
    return _avatars[id];
  }

  @override
  Future<bool> hasAvatar(String id) async {
    _ensurePermission();
    return _avatars.containsKey(id);
  }

  @override
  Future<Contact> createContact(Contact contact) async {
    _ensurePermission();
    final id = contact.id.isEmpty ? 'c${_nextContactId++}' : contact.id;
    final created = contact.copyWith(
      id: id,
      displayName: contact.displayName ?? _fallbackDisplayName(contact),
      updatedAt: DateTime.now(),
    );
    _contacts[id] = created;
    emitChange(ContactChangeEvent(
      type: ContactChangeType.added,
      contactId: id,
      timestamp: DateTime.now(),
    ));
    return created;
  }

  @override
  Future<Contact> updateContact(Contact contact) async {
    _ensurePermission();
    if (!_contacts.containsKey(contact.id)) {
      throw ContactNotFoundException(contact.id);
    }
    final updated = contact.copyWith(updatedAt: DateTime.now());
    _contacts[contact.id] = updated;
    emitChange(ContactChangeEvent(
      type: ContactChangeType.updated,
      contactId: contact.id,
      timestamp: DateTime.now(),
    ));
    return updated;
  }

  @override
  Future<void> deleteContact(String id) async {
    _ensurePermission();
    if (_contacts.remove(id) == null) {
      throw ContactNotFoundException(id);
    }
    _avatars.remove(id);
    emitChange(ContactChangeEvent(
      type: ContactChangeType.deleted,
      contactId: id,
      timestamp: DateTime.now(),
    ));
  }

  @override
  Future<void> deleteContacts(List<String> ids) async {
    for (final id in ids) {
      await deleteContact(id);
    }
  }

  @override
  Future<List<ContactGroup>> getGroups() async {
    _ensurePermission();
    return _groups.values.toList(growable: false);
  }

  @override
  Future<ContactGroup> createGroup(String name) async {
    _ensurePermission();
    final id = 'g${_nextGroupId++}';
    final group = ContactGroup(id: id, name: name, memberCount: 0);
    _groups[id] = group;
    return group;
  }

  @override
  Future<void> deleteGroup(String id) async {
    _ensurePermission();
    if (_groups.remove(id) == null) {
      throw GroupNotFoundException(id);
    }
  }

  @override
  Future<void> addContactsToGroup(
    String groupId,
    List<String> contactIds,
  ) async {
    _ensurePermission();
    final group = _groups[groupId];
    if (group == null) throw GroupNotFoundException(groupId);
    for (final id in contactIds) {
      final contact = _contacts[id];
      if (contact == null) throw ContactNotFoundException(id);
      if (!contact.groupIds.contains(groupId)) {
        _contacts[id] = contact.copyWith(
          groupIds: [...contact.groupIds, groupId],
        );
      }
    }
    _groups[groupId] = group.copyWith(
      memberCount: _contacts.values
          .where((c) => c.groupIds.contains(groupId))
          .length,
    );
  }

  @override
  Future<void> removeContactsFromGroup(
    String groupId,
    List<String> contactIds,
  ) async {
    _ensurePermission();
    final group = _groups[groupId];
    if (group == null) throw GroupNotFoundException(groupId);
    for (final id in contactIds) {
      final contact = _contacts[id];
      if (contact == null) continue;
      _contacts[id] = contact.copyWith(
        groupIds: contact.groupIds.where((g) => g != groupId).toList(),
      );
    }
    _groups[groupId] = group.copyWith(
      memberCount: _contacts.values
          .where((c) => c.groupIds.contains(groupId))
          .length,
    );
  }

  @override
  Stream<ContactChangeEvent> watchContactsChanged() => _changes.stream;

  List<Contact> _sorted(
    List<Contact> list, [
    ContactSort sort = ContactSort.displayNameAsc,
  ]) {
    final copy = List<Contact>.of(list);
    int byName(Contact a, Contact b) =>
        (a.displayName ?? '').toLowerCase().compareTo(
              (b.displayName ?? '').toLowerCase(),
            );
    switch (sort) {
      case ContactSort.displayNameAsc:
        copy.sort(byName);
      case ContactSort.displayNameDesc:
        copy.sort((a, b) => byName(b, a));
      case ContactSort.updatedAtDesc:
        copy.sort((a, b) {
          final at = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
    }
    return copy;
  }

  ContactPage _pageFor(List<Contact> all, ContactQuery query) {
    var filtered = all;
    if (query.groupId != null) {
      filtered =
          filtered.where((c) => c.groupIds.contains(query.groupId)).toList();
    }
    filtered = _sorted(filtered, query.sort);

    final offset = int.tryParse(query.pageToken ?? '0') ?? 0;
    final end = (offset + query.pageSize).clamp(0, filtered.length);
    final slice = filtered.sublist(offset.clamp(0, filtered.length), end);
    final projected =
        slice.map((c) => _project(c, query.fields)).toList(growable: false);
    final next = end < filtered.length ? '$end' : null;
    return ContactPage(
      contacts: projected,
      nextPageToken: next,
      estimatedTotal: filtered.length,
    );
  }

  Contact _project(Contact contact, Set<ContactField> fields) {
    // Id is always retained so projected contacts remain addressable.
    return Contact(
      id: contact.id,
      displayName: fields.contains(ContactField.displayName)
          ? contact.displayName
          : null,
      name: fields.contains(ContactField.name) ? contact.name : null,
      phones: fields.contains(ContactField.phones) ? contact.phones : const [],
      emails: fields.contains(ContactField.emails) ? contact.emails : const [],
      addresses:
          fields.contains(ContactField.addresses) ? contact.addresses : const [],
      organization: fields.contains(ContactField.organization)
          ? contact.organization
          : null,
      note: fields.contains(ContactField.note) ? contact.note : null,
      websites:
          fields.contains(ContactField.websites) ? contact.websites : const [],
      socialProfiles: fields.contains(ContactField.socialProfiles)
          ? contact.socialProfiles
          : const [],
      relations: fields.contains(ContactField.relations)
          ? contact.relations
          : const [],
      events: fields.contains(ContactField.events) ? contact.events : const [],
      groupIds:
          fields.contains(ContactField.groupIds) ? contact.groupIds : const [],
      isFavorite: fields.contains(ContactField.isFavorite)
          ? contact.isFavorite
          : false,
      updatedAt:
          fields.contains(ContactField.updatedAt) ? contact.updatedAt : null,
    );
  }

  String? _fallbackDisplayName(Contact contact) {
    final given = contact.name?.givenName;
    final family = contact.name?.familyName;
    final parts = [given, family].whereType<String>().where((s) => s.isNotEmpty);
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }
}
