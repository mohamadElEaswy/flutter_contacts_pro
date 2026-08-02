import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../models/avatar_size.dart';
import '../models/contact.dart';
import '../models/contact_change.dart';
import '../models/contact_fields.dart';
import '../models/contact_group.dart';
import '../models/permission_status.dart';
import '../query/contact_page.dart';
import '../query/contact_query.dart';
import 'unimplemented_contacts_platform.dart';

/// Platform interface for contacts operations.
///
/// Speaks domain types. On Android, register the JNIGEN implementation via
/// `package:flutter_contacts_pro/android.dart`. iOS / Pigeon land later.
abstract class ContactsPlatform extends PlatformInterface {
  ContactsPlatform() : super(token: _token);

  static final Object _token = Object();

  static ContactsPlatform _instance = UnimplementedContactsPlatform();

  /// The default instance of [ContactsPlatform] to use.
  static ContactsPlatform get instance => _instance;

  /// Platform-specific implementations set this when they register.
  static set instance(ContactsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // —— Permissions ——

  Future<PermissionStatus> getPermissionStatus({
    PermissionMode mode = PermissionMode.read,
  }) {
    throw UnimplementedError('getPermissionStatus() has not been implemented.');
  }

  Future<PermissionStatus> requestPermission({
    PermissionMode mode = PermissionMode.read,
  }) {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  Future<bool> openSettings() {
    throw UnimplementedError('openSettings() has not been implemented.');
  }

  // —— Read ——

  Future<ContactPage> getContacts(ContactQuery query) {
    throw UnimplementedError('getContacts() has not been implemented.');
  }

  Future<ContactPage> search(String query, ContactQuery options) {
    throw UnimplementedError('search() has not been implemented.');
  }

  Future<Contact?> getContact(String id, Set<ContactField> fields) {
    throw UnimplementedError('getContact() has not been implemented.');
  }

  Future<Uint8List?> getAvatar(String id, AvatarSize size) {
    throw UnimplementedError('getAvatar() has not been implemented.');
  }

  Future<bool> hasAvatar(String id) {
    throw UnimplementedError('hasAvatar() has not been implemented.');
  }

  // —— Write ——

  Future<Contact> createContact(Contact contact) {
    throw UnimplementedError('createContact() has not been implemented.');
  }

  Future<Contact> updateContact(Contact contact) {
    throw UnimplementedError('updateContact() has not been implemented.');
  }

  Future<void> deleteContact(String id) {
    throw UnimplementedError('deleteContact() has not been implemented.');
  }

  Future<void> deleteContacts(List<String> ids) {
    throw UnimplementedError('deleteContacts() has not been implemented.');
  }

  // —— Groups ——

  Future<List<ContactGroup>> getGroups() {
    throw UnimplementedError('getGroups() has not been implemented.');
  }

  Future<ContactGroup> createGroup(String name) {
    throw UnimplementedError('createGroup() has not been implemented.');
  }

  Future<void> deleteGroup(String id) {
    throw UnimplementedError('deleteGroup() has not been implemented.');
  }

  Future<void> addContactsToGroup(String groupId, List<String> contactIds) {
    throw UnimplementedError('addContactsToGroup() has not been implemented.');
  }

  Future<void> removeContactsFromGroup(
    String groupId,
    List<String> contactIds,
  ) {
    throw UnimplementedError(
      'removeContactsFromGroup() has not been implemented.',
    );
  }

  // —— Observation ——

  Stream<ContactChangeEvent> watchContactsChanged() {
    throw UnimplementedError(
      'watchContactsChanged() has not been implemented.',
    );
  }
}
