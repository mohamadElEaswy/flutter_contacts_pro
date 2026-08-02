import 'dart:typed_data';

import '../errors/contacts_exception.dart';
import '../models/avatar_size.dart';
import '../models/contact.dart';
import '../models/contact_change.dart';
import '../models/contact_fields.dart';
import '../models/contact_group.dart';
import '../models/permission_status.dart';
import '../platform/contacts_platform.dart';
import '../query/contact_page.dart';
import '../query/contact_query.dart';

/// Public Dart API for reading and writing device contacts.
///
/// Prefer [FlutterContactsPro.instance] for app code. Inject a custom
/// [ContactsPlatform] (e.g. a fake) in tests via the constructor.
class FlutterContactsPro {
  FlutterContactsPro({ContactsPlatform? platform}) : _override = platform;

  /// Shared singleton that uses the registered [ContactsPlatform.instance].
  static final FlutterContactsPro instance = FlutterContactsPro();

  final ContactsPlatform? _override;

  ContactsPlatform get _platform => _override ?? ContactsPlatform.instance;

  // —— Permissions ——

  /// Returns the current permission status for [mode].
  Future<PermissionStatus> getPermissionStatus({
    PermissionMode mode = PermissionMode.read,
  }) {
    return _platform.getPermissionStatus(mode: mode);
  }

  /// Requests contacts permission for [mode].
  Future<PermissionStatus> requestPermission({
    PermissionMode mode = PermissionMode.read,
  }) {
    return _platform.requestPermission(mode: mode);
  }

  /// Opens the system settings page for this app.
  Future<bool> openSettings() => _platform.openSettings();

  // —— Read ——

  /// Fetches a page of contacts.
  ///
  /// Avatars are never included; use [getAvatar].
  Future<ContactPage> getContacts({ContactQuery query = const ContactQuery()}) {
    return _platform.getContacts(query.normalized());
  }

  /// Searches contacts matching [query].
  ///
  /// Returns an empty [ContactPage] when there are no matches.
  Future<ContactPage> search(String query, {ContactQuery? options}) {
    final normalizedQuery = query.trim();
    final opts = (options ?? const ContactQuery()).normalized();
    if (normalizedQuery.isEmpty) {
      return Future.value(ContactPage.empty);
    }
    return _platform.search(normalizedQuery, opts);
  }

  /// Returns a single contact by [id], or null if not found.
  Future<Contact?> getContact(String id, {Set<ContactField>? fields}) {
    if (id.isEmpty) {
      throw const InvalidContactException('Contact id must not be empty.');
    }
    return _platform.getContact(id, fields ?? ContactFields.detail);
  }

  /// Loads avatar bytes for [id], or null if none exists.
  Future<Uint8List?> getAvatar(
    String id, {
    AvatarSize size = AvatarSize.thumbnail,
  }) {
    if (id.isEmpty) {
      throw const InvalidContactException('Contact id must not be empty.');
    }
    return _platform.getAvatar(id, size);
  }

  /// Whether the contact has an avatar on the device.
  Future<bool> hasAvatar(String id) {
    if (id.isEmpty) {
      throw const InvalidContactException('Contact id must not be empty.');
    }
    return _platform.hasAvatar(id);
  }

  // —— Write ——

  /// Creates a new contact and returns the persisted record (with id).
  Future<Contact> createContact(Contact contact) {
    return _platform.createContact(contact);
  }

  /// Updates an existing contact. [Contact.id] must be non-empty.
  Future<Contact> updateContact(Contact contact) {
    if (contact.id.isEmpty) {
      throw const InvalidContactException(
        'Contact id is required for updateContact.',
      );
    }
    return _platform.updateContact(contact);
  }

  /// Deletes a contact by [id].
  Future<void> deleteContact(String id) {
    if (id.isEmpty) {
      throw const InvalidContactException('Contact id must not be empty.');
    }
    return _platform.deleteContact(id);
  }

  /// Deletes multiple contacts. Not transactional across platforms.
  Future<void> deleteContacts(List<String> ids) {
    final cleaned = ids.where((id) => id.isNotEmpty).toList(growable: false);
    if (cleaned.isEmpty) return Future.value();
    return _platform.deleteContacts(cleaned);
  }

  // —— Groups ——

  /// Lists contact groups.
  Future<List<ContactGroup>> getGroups() => _platform.getGroups();

  /// Creates a group with [name].
  Future<ContactGroup> createGroup(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const InvalidContactException('Group name must not be empty.');
    }
    return _platform.createGroup(trimmed);
  }

  /// Deletes a group by [id].
  Future<void> deleteGroup(String id) {
    if (id.isEmpty) {
      throw const InvalidContactException('Group id must not be empty.');
    }
    return _platform.deleteGroup(id);
  }

  /// Adds contacts to a group.
  Future<void> addContactsToGroup(String groupId, List<String> contactIds) {
    if (groupId.isEmpty) {
      throw const InvalidContactException('Group id must not be empty.');
    }
    final cleaned = contactIds
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (cleaned.isEmpty) return Future.value();
    return _platform.addContactsToGroup(groupId, cleaned);
  }

  /// Removes contacts from a group.
  Future<void> removeContactsFromGroup(
    String groupId,
    List<String> contactIds,
  ) {
    if (groupId.isEmpty) {
      throw const InvalidContactException('Group id must not be empty.');
    }
    final cleaned = contactIds
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (cleaned.isEmpty) return Future.value();
    return _platform.removeContactsFromGroup(groupId, cleaned);
  }

  // —— Observation ——

  /// Stream of contact store changes.
  ///
  /// Platforms may emit [ContactChangeType.unknown] without a contact id when
  /// only a coarse "reload" signal is available.
  Stream<ContactChangeEvent> get onContactsChanged =>
      _platform.watchContactsChanged();

  // —— Cache ——

  /// Clears any Dart-side contact cache.
  ///
  /// No-op until a caching layer is wired; safe to call.
  void clearCache() {
    // Reserved for the upcoming in-memory LRU cache.
  }
}
