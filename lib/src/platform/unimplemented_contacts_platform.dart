import 'dart:typed_data';

import '../models/avatar_size.dart';
import '../models/contact.dart';
import '../models/contact_change.dart';
import '../models/contact_fields.dart';
import '../models/contact_group.dart';
import '../models/permission_status.dart';
import '../query/contact_page.dart';
import '../query/contact_query.dart';
import 'contacts_platform.dart';

/// Default platform stub until Pigeon native implementations are wired.
class UnimplementedContactsPlatform extends ContactsPlatform {
  @override
  Future<PermissionStatus> getPermissionStatus({
    PermissionMode mode = PermissionMode.read,
  }) {
    throw UnimplementedError('getPermissionStatus() has not been implemented.');
  }

  @override
  Future<PermissionStatus> requestPermission({
    PermissionMode mode = PermissionMode.read,
  }) {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  @override
  Future<bool> openSettings() {
    throw UnimplementedError('openSettings() has not been implemented.');
  }

  @override
  Future<ContactPage> getContacts(ContactQuery query) {
    throw UnimplementedError('getContacts() has not been implemented.');
  }

  @override
  Future<ContactPage> search(String query, ContactQuery options) {
    throw UnimplementedError('search() has not been implemented.');
  }

  @override
  Future<Contact?> getContact(String id, Set<ContactField> fields) {
    throw UnimplementedError('getContact() has not been implemented.');
  }

  @override
  Future<Uint8List?> getAvatar(String id, AvatarSize size) {
    throw UnimplementedError('getAvatar() has not been implemented.');
  }

  @override
  Future<bool> hasAvatar(String id) {
    throw UnimplementedError('hasAvatar() has not been implemented.');
  }

  @override
  Future<Contact> createContact(Contact contact) {
    throw UnimplementedError('createContact() has not been implemented.');
  }

  @override
  Future<Contact> updateContact(Contact contact) {
    throw UnimplementedError('updateContact() has not been implemented.');
  }

  @override
  Future<void> deleteContact(String id) {
    throw UnimplementedError('deleteContact() has not been implemented.');
  }

  @override
  Future<void> deleteContacts(List<String> ids) {
    throw UnimplementedError('deleteContacts() has not been implemented.');
  }

  @override
  Future<List<ContactGroup>> getGroups() {
    throw UnimplementedError('getGroups() has not been implemented.');
  }

  @override
  Future<ContactGroup> createGroup(String name) {
    throw UnimplementedError('createGroup() has not been implemented.');
  }

  @override
  Future<void> deleteGroup(String id) {
    throw UnimplementedError('deleteGroup() has not been implemented.');
  }

  @override
  Future<void> addContactsToGroup(String groupId, List<String> contactIds) {
    throw UnimplementedError('addContactsToGroup() has not been implemented.');
  }

  @override
  Future<void> removeContactsFromGroup(
    String groupId,
    List<String> contactIds,
  ) {
    throw UnimplementedError(
      'removeContactsFromGroup() has not been implemented.',
    );
  }

  @override
  Stream<ContactChangeEvent> watchContactsChanged() {
    throw UnimplementedError(
      'watchContactsChanged() has not been implemented.',
    );
  }
}
