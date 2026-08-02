import 'dart:typed_data';

import 'package:jni/jni.dart';

import '../errors/contacts_exception.dart';
import '../models/avatar_size.dart';
import '../models/contact.dart';
import '../models/contact_change.dart';
import '../models/contact_fields.dart';
import '../models/contact_group.dart';
import '../models/email.dart';
import '../models/permission_status.dart';
import '../models/phone.dart';
import '../platform/contacts_platform.dart';
import '../query/contact_page.dart';
import '../query/contact_query.dart';
import '../query/contact_sort.dart';
import 'android_change_stream.dart';
import 'android_contact_columns.dart';
import 'android_permissions.dart';
import 'bindings/contacts_android.g.dart' as android;
import 'contact_cursor_mapper.dart';

/// Android [ContactsPlatform] backed by JNIGEN ContactsContract bindings.
class AndroidContactsPlatform extends ContactsPlatform {
  AndroidContactsPlatform({
    AndroidPermissions? permissions,
    AndroidChangeStream? changes,
    ContactCursorMapper? mapper,
  })  : _permissions = permissions ?? AndroidPermissions(),
        _changes = changes ?? AndroidChangeStream(),
        _mapper = mapper ?? const ContactCursorMapper();

  final AndroidPermissions _permissions;
  final AndroidChangeStream _changes;
  final ContactCursorMapper _mapper;

  android.Context _appContext() =>
      android.Context.fromReference(Jni.getCachedApplicationContext());

  android.ContentResolver _resolver(android.Context ctx) {
    final resolver = ctx.getContentResolver();
    if (resolver == null) {
      throw const PlatformContactsException(
        'NO_RESOLVER',
        'ContentResolver unavailable',
      );
    }
    return resolver;
  }

  Future<void> _ensureRead() async {
    final status = await _permissions.getStatus();
    if (status != PermissionStatus.granted &&
        status != PermissionStatus.limited) {
      throw const PermissionDeniedException(
        'READ_CONTACTS permission is required.',
        mode: 'read',
      );
    }
  }

  Future<void> _ensureWrite() async {
    final status =
        await _permissions.getStatus(mode: PermissionMode.readWrite);
    if (status != PermissionStatus.granted) {
      throw const PermissionDeniedException(
        'WRITE_CONTACTS permission is required.',
        mode: 'readWrite',
      );
    }
  }

  @override
  Future<PermissionStatus> getPermissionStatus({
    PermissionMode mode = PermissionMode.read,
  }) =>
      _permissions.getStatus(mode: mode);

  @override
  Future<PermissionStatus> requestPermission({
    PermissionMode mode = PermissionMode.read,
  }) =>
      _permissions.request(mode: mode);

  @override
  Future<bool> openSettings() => _permissions.openSettings();

  @override
  Stream<ContactChangeEvent> watchContactsChanged() => _changes.watch();

  @override
  Future<ContactPage> getContacts(ContactQuery query) async {
    await _ensureRead();
    return _queryContactsPage(
      uri: android.ContactsContract$Contacts.CONTENT_URI,
      query: query,
      selection: null,
      selectionArgs: null,
    );
  }

  @override
  Future<ContactPage> search(String query, ContactQuery options) async {
    await _ensureRead();
    final filterBase = android.ContactsContract$Contacts.CONTENT_FILTER_URI;
    if (filterBase == null) {
      throw const PlatformContactsException(
        'NO_FILTER_URI',
        'CONTENT_FILTER_URI unavailable',
      );
    }
    final uri = android.Uri.withAppendedPath(
      filterBase,
      Uri.encodeComponent(query).toJString(),
    );
    return _queryContactsPage(
      uri: uri,
      query: options,
      selection: null,
      selectionArgs: null,
    );
  }

  @override
  Future<Contact?> getContact(String id, Set<ContactField> fields) async {
    await _ensureRead();
    final contactId = int.tryParse(id);
    if (contactId == null) return null;

    final ctx = _appContext();
    final resolver = _resolver(ctx);
    try {
      final uri = android.ContentUris.withAppendedId(
        android.ContactsContract$Contacts.CONTENT_URI,
        contactId,
      );
      final projection = _contactsProjection(fields);
      final cursor = resolver.query$1(
        uri,
        projection,
        null,
        null,
        null,
      );
      if (cursor == null) return null;
      try {
        if (!cursor.moveToNext()) return null;
        final row = _readContactsRow(cursor, fields);
        var contact = _mapper.fromContactsRow(row, fields: fields);
        if (_needsDataTable(fields)) {
          final dataRows = _loadDataRows(resolver, id, fields);
          contact = _mapper.mergeDataRows(contact, dataRows, fields: fields);
        }
        return contact;
      } finally {
        cursor.close();
        cursor.release();
      }
    } on JniException catch (e) {
      throw PlatformContactsException('GET_CONTACT', e.toString());
    } finally {
      resolver.release();
      ctx.release();
    }
  }

  @override
  Future<Uint8List?> getAvatar(String id, AvatarSize size) async {
    await _ensureRead();
    final contactId = int.tryParse(id);
    if (contactId == null) return null;

    final ctx = _appContext();
    final resolver = _resolver(ctx);
    try {
      final contactUri = android.ContentUris.withAppendedId(
        android.ContactsContract$Contacts.CONTENT_URI,
        contactId,
      );
      final preferHighRes = size == AvatarSize.full;
      final stream = android.ContactsContract$Contacts
          .openContactPhotoInputStream$1(resolver, contactUri, preferHighRes);
      if (stream == null) return null;
      try {
        return _readFully(stream);
      } finally {
        stream.close();
        stream.release();
      }
    } on JniException catch (e) {
      throw PlatformContactsException('GET_AVATAR', e.toString());
    } finally {
      resolver.release();
      ctx.release();
    }
  }

  @override
  Future<bool> hasAvatar(String id) async {
    final bytes = await getAvatar(id, AvatarSize.thumbnail);
    return bytes != null && bytes.isNotEmpty;
  }

  @override
  Future<Contact> createContact(Contact contact) async {
    await _ensureWrite();
    final ctx = _appContext();
    final resolver = _resolver(ctx);
    try {
      final ops = JList.array(android.ContentProviderOperation.type);
      final rawInsert = android.ContentProviderOperation.newInsert(
        android.ContactsContract$RawContacts.CONTENT_URI,
      )!;
      final rawValues = android.ContentValues();
      rawValues.put$8('account_type'.toJString(), null);
      rawValues.put$8('account_name'.toJString(), null);
      rawInsert.withValues(rawValues);
      ops.add(rawInsert.build()!);
      rawValues.release();

      _appendDataInserts(ops, contact, backRef: 0);

      final results = resolver.applyBatch(
        AndroidContactColumns.authority.toJString(),
        ops,
      );
      ops.release();
      if (results == null || results.isEmpty) {
        throw const PlatformContactsException(
          'CREATE_FAILED',
          'applyBatch returned no results',
        );
      }
      results.release();

      // Re-query newest matching display name / phone as best effort.
      final created = await _findCreated(contact);
      if (created != null) return created;
      throw const PlatformContactsException(
        'CREATE_FAILED',
        'Contact created but could not be reloaded',
      );
    } on JniException catch (e) {
      throw PlatformContactsException('CREATE_CONTACT', e.toString());
    } finally {
      resolver.release();
      ctx.release();
    }
  }

  @override
  Future<Contact> updateContact(Contact contact) async {
    await _ensureWrite();
    if (contact.id.isEmpty) {
      throw const InvalidContactException('Contact id is required for update.');
    }
    final existing = await getContact(contact.id, ContactFields.minimal);
    if (existing == null) {
      throw ContactNotFoundException(contact.id);
    }

    final rawId = await _primaryRawContactId(contact.id);
    if (rawId == null) {
      throw ContactNotFoundException(contact.id);
    }

    final ctx = _appContext();
    final resolver = _resolver(ctx);
    try {
      final args = _stringArray([contact.id]);
      resolver.delete$1(
        android.ContactsContract$Data.CONTENT_URI,
        '${AndroidContactColumns.contactId}=?'.toJString(),
        args,
      );
      args.release();

      final ops = JList.array(android.ContentProviderOperation.type);
      _appendDataInsertsForRawContact(ops, contact, rawContactId: rawId);
      final results = resolver.applyBatch(
        AndroidContactColumns.authority.toJString(),
        ops,
      );
      ops.release();
      results?.release();

      return (await getContact(contact.id, ContactFields.detail)) ?? contact;
    } on JniException catch (e) {
      throw PlatformContactsException('UPDATE_CONTACT', e.toString());
    } finally {
      resolver.release();
      ctx.release();
    }
  }

  @override
  Future<void> deleteContact(String id) async {
    await _ensureWrite();
    final contactId = int.tryParse(id);
    if (contactId == null) {
      throw ContactNotFoundException(id);
    }

    final ctx = _appContext();
    final resolver = _resolver(ctx);
    try {
      final uri = android.ContentUris.withAppendedId(
        android.ContactsContract$Contacts.CONTENT_URI,
        contactId,
      );
      final deleted = resolver.delete$1(uri, null, null);
      if (deleted == 0) {
        throw ContactNotFoundException(id);
      }
    } on JniException catch (e) {
      throw PlatformContactsException('DELETE_CONTACT', e.toString());
    } finally {
      resolver.release();
      ctx.release();
    }
  }

  @override
  Future<void> deleteContacts(List<String> ids) async {
    for (final id in ids) {
      await deleteContact(id);
    }
  }

  @override
  Future<List<ContactGroup>> getGroups() async {
    throw UnimplementedError(
      'getGroups() is deferred to a later Android phase.',
    );
  }

  @override
  Future<ContactGroup> createGroup(String name) async {
    throw UnimplementedError(
      'createGroup() is deferred to a later Android phase.',
    );
  }

  @override
  Future<void> deleteGroup(String id) async {
    throw UnimplementedError(
      'deleteGroup() is deferred to a later Android phase.',
    );
  }

  @override
  Future<void> addContactsToGroup(
    String groupId,
    List<String> contactIds,
  ) async {
    throw UnimplementedError(
      'addContactsToGroup() is deferred to a later Android phase.',
    );
  }

  @override
  Future<void> removeContactsFromGroup(
    String groupId,
    List<String> contactIds,
  ) async {
    throw UnimplementedError(
      'removeContactsFromGroup() is deferred to a later Android phase.',
    );
  }

  Future<ContactPage> _queryContactsPage({
    required android.Uri? uri,
    required ContactQuery query,
    required String? selection,
    required JArray<JString?>? selectionArgs,
  }) async {
    final ctx = _appContext();
    final resolver = _resolver(ctx);
    try {
      final offset = int.tryParse(query.pageToken ?? '0') ?? 0;
      final sort = _sortOrder(query.sort);
      final projection = _contactsProjection(query.fields);
      final cursor = resolver.query$1(
        uri,
        projection,
        selection?.toJString(),
        selectionArgs,
        sort.toJString(),
      );
      if (cursor == null) {
        return ContactPage.empty;
      }
      try {
        final total = cursor.getCount();
        final contacts = <Contact>[];
        if (offset > 0) {
          cursor.moveToPosition(offset - 1);
        }
        var taken = 0;
        while (taken < query.pageSize && cursor.moveToNext()) {
          final row = _readContactsRow(cursor, query.fields);
          var contact = _mapper.fromContactsRow(row, fields: query.fields);
          if (_needsDataTable(query.fields)) {
            final dataRows =
                _loadDataRows(resolver, contact.id, query.fields);
            contact =
                _mapper.mergeDataRows(contact, dataRows, fields: query.fields);
          }
          if (query.groupId != null &&
              !contact.groupIds.contains(query.groupId)) {
            continue;
          }
          contacts.add(contact);
          taken++;
        }
        final nextOffset = offset + taken;
        final nextToken = nextOffset < total ? '$nextOffset' : null;
        return ContactPage(
          contacts: contacts,
          nextPageToken: nextToken,
          estimatedTotal: total,
        );
      } finally {
        cursor.close();
        cursor.release();
      }
    } on JniException catch (e) {
      throw PlatformContactsException('QUERY_CONTACTS', e.toString());
    } finally {
      resolver.release();
      ctx.release();
    }
  }

  JArray<JString?> _contactsProjection(Set<ContactField> fields) {
    final cols = <String>{AndroidContactColumns.id};
    if (fields.contains(ContactField.displayName)) {
      cols.add(AndroidContactColumns.displayName);
    }
    if (fields.contains(ContactField.isFavorite)) {
      cols.add(AndroidContactColumns.starred);
    }
    if (fields.contains(ContactField.updatedAt)) {
      cols.add(AndroidContactColumns.contactLastUpdatedTimestamp);
    }
    return _stringArray(cols.toList());
  }

  bool _needsDataTable(Set<ContactField> fields) {
    const dataFields = {
      ContactField.name,
      ContactField.phones,
      ContactField.emails,
      ContactField.addresses,
      ContactField.organization,
      ContactField.note,
      ContactField.websites,
      ContactField.socialProfiles,
      ContactField.relations,
      ContactField.events,
      ContactField.groupIds,
    };
    return fields.any(dataFields.contains);
  }

  List<Map<String, Object?>> _loadDataRows(
    android.ContentResolver resolver,
    String contactId,
    Set<ContactField> fields,
  ) {
    final selection =
        '${AndroidContactColumns.contactId}=?';
    final args = _stringArray([contactId]);
    final projection = _stringArray([
      AndroidContactColumns.mimeType,
      AndroidContactColumns.data1,
      AndroidContactColumns.data2,
      AndroidContactColumns.data3,
      AndroidContactColumns.data4,
      AndroidContactColumns.data5,
      AndroidContactColumns.data6,
      AndroidContactColumns.data7,
      AndroidContactColumns.data8,
      AndroidContactColumns.data9,
      AndroidContactColumns.data10,
      AndroidContactColumns.isPrimary,
      AndroidContactColumns.isSuperPrimary,
    ]);
    final cursor = resolver.query$1(
      android.ContactsContract$Data.CONTENT_URI,
      projection,
      selection.toJString(),
      args,
      null,
    );
    args.release();
    projection.release();
    if (cursor == null) return const [];
    try {
      final rows = <Map<String, Object?>>[];
      while (cursor.moveToNext()) {
        rows.add(_readDataRow(cursor));
      }
      return rows;
    } finally {
      cursor.close();
      cursor.release();
    }
  }

  Map<String, Object?> _readContactsRow(
    android.Cursor cursor,
    Set<ContactField> fields,
  ) {
    final map = <String, Object?>{};
    void put(String col) {
      final idx = cursor.getColumnIndex(col.toJString());
      if (idx < 0 || cursor.isNull$1(idx)) {
        map[col] = null;
        return;
      }
      // Prefer string; numeric columns still stringify.
      final s = cursor.getString(idx);
      if (s != null) {
        final dart = s.toDartString();
        s.release();
        final asInt = int.tryParse(dart);
        map[col] = asInt ?? dart;
      } else {
        map[col] = cursor.getLong(idx);
      }
    }

    put(AndroidContactColumns.id);
    if (fields.contains(ContactField.displayName)) {
      put(AndroidContactColumns.displayName);
    }
    if (fields.contains(ContactField.isFavorite)) {
      put(AndroidContactColumns.starred);
    }
    if (fields.contains(ContactField.updatedAt)) {
      put(AndroidContactColumns.contactLastUpdatedTimestamp);
    }
    return map;
  }

  Map<String, Object?> _readDataRow(android.Cursor cursor) {
    final keys = [
      AndroidContactColumns.mimeType,
      AndroidContactColumns.data1,
      AndroidContactColumns.data2,
      AndroidContactColumns.data3,
      AndroidContactColumns.data4,
      AndroidContactColumns.data5,
      AndroidContactColumns.data6,
      AndroidContactColumns.data7,
      AndroidContactColumns.data8,
      AndroidContactColumns.data9,
      AndroidContactColumns.data10,
      AndroidContactColumns.isPrimary,
      AndroidContactColumns.isSuperPrimary,
    ];
    final map = <String, Object?>{};
    for (final col in keys) {
      final idx = cursor.getColumnIndex(col.toJString());
      if (idx < 0 || cursor.isNull$1(idx)) {
        map[col] = null;
        continue;
      }
      final s = cursor.getString(idx);
      if (s != null) {
        final dart = s.toDartString();
        s.release();
        final asInt = int.tryParse(dart);
        map[col] = asInt ?? dart;
      } else {
        map[col] = cursor.getLong(idx);
      }
    }
    return map;
  }

  String _sortOrder(ContactSort sort) {
    return switch (sort) {
      ContactSort.displayNameAsc =>
        '${AndroidContactColumns.displayName} COLLATE LOCALIZED ASC',
      ContactSort.displayNameDesc =>
        '${AndroidContactColumns.displayName} COLLATE LOCALIZED DESC',
      ContactSort.updatedAtDesc =>
        '${AndroidContactColumns.contactLastUpdatedTimestamp} DESC',
    };
  }

  void _appendDataInserts(
    JList<android.ContentProviderOperation?> ops,
    Contact contact, {
    required int backRef,
  }) {
    void insertMime(
      String mime,
      void Function(android.ContentValues values) fill,
    ) {
      final builder = android.ContentProviderOperation.newInsert(
        android.ContactsContract$Data.CONTENT_URI,
      )!;
      final values = android.ContentValues();
      values.put$8(
        AndroidContactColumns.mimeType.toJString(),
        mime.toJString(),
      );
      fill(values);
      builder.withValueBackReference('raw_contact_id'.toJString(), backRef);
      builder.withValues(values);
      ops.add(builder.build()!);
      values.release();
    }

    _fillMimeInserts(insertMime, contact);
  }

  void _appendDataInsertsForRawContact(
    JList<android.ContentProviderOperation?> ops,
    Contact contact, {
    required int rawContactId,
  }) {
    void insertMime(
      String mime,
      void Function(android.ContentValues values) fill,
    ) {
      final builder = android.ContentProviderOperation.newInsert(
        android.ContactsContract$Data.CONTENT_URI,
      )!;
      final values = android.ContentValues();
      values.put$8(
        AndroidContactColumns.mimeType.toJString(),
        mime.toJString(),
      );
      _putInt(values, 'raw_contact_id', rawContactId);
      fill(values);
      builder.withValues(values);
      ops.add(builder.build()!);
      values.release();
    }

    _fillMimeInserts(insertMime, contact);
  }

  void _fillMimeInserts(
    void Function(
      String mime,
      void Function(android.ContentValues values) fill,
    ) insertMime,
    Contact contact,
  ) {
    if (contact.name != null ||
        (contact.displayName != null && contact.displayName!.isNotEmpty)) {
      insertMime(AndroidContactColumns.mimeStructuredName, (v) {
        final n = contact.name;
        _putString(v, AndroidContactColumns.data1, contact.displayName);
        _putString(v, AndroidContactColumns.data2, n?.givenName);
        _putString(v, AndroidContactColumns.data3, n?.familyName);
        _putString(v, AndroidContactColumns.data4, n?.prefix);
        _putString(v, AndroidContactColumns.data5, n?.middleName);
        _putString(v, AndroidContactColumns.data6, n?.suffix);
      });
    }

    for (final phone in contact.phones) {
      insertMime(AndroidContactColumns.mimePhone, (v) {
        _putString(v, AndroidContactColumns.data1, phone.number);
        _putInt(v, AndroidContactColumns.data2, _phoneType(phone.label));
        _putString(v, AndroidContactColumns.data3, phone.customLabel);
      });
    }

    for (final email in contact.emails) {
      insertMime(AndroidContactColumns.mimeEmail, (v) {
        _putString(v, AndroidContactColumns.data1, email.address);
        _putInt(v, AndroidContactColumns.data2, _emailType(email.label));
        _putString(v, AndroidContactColumns.data3, email.customLabel);
      });
    }

    if (contact.organization != null) {
      insertMime(AndroidContactColumns.mimeOrganization, (v) {
        _putString(v, AndroidContactColumns.data1, contact.organization!.company);
        _putString(v, AndroidContactColumns.data4, contact.organization!.jobTitle);
        _putString(
          v,
          AndroidContactColumns.data5,
          contact.organization!.department,
        );
      });
    }

    if (contact.note != null && contact.note!.isNotEmpty) {
      insertMime(AndroidContactColumns.mimeNote, (v) {
        _putString(v, AndroidContactColumns.data1, contact.note);
      });
    }

    for (final web in contact.websites) {
      insertMime(AndroidContactColumns.mimeWebsite, (v) {
        _putString(v, AndroidContactColumns.data1, web.url);
      });
    }
  }

  Future<int?> _primaryRawContactId(String contactId) async {
    final ctx = _appContext();
    final resolver = _resolver(ctx);
    try {
      final args = _stringArray([contactId]);
      final projection = _stringArray([AndroidContactColumns.id]);
      final cursor = resolver.query$1(
        android.ContactsContract$RawContacts.CONTENT_URI,
        projection,
        'contact_id=?'.toJString(),
        args,
        null,
      );
      args.release();
      projection.release();
      if (cursor == null) return null;
      try {
        if (!cursor.moveToNext()) return null;
        final idx = cursor.getColumnIndex(AndroidContactColumns.id.toJString());
        return cursor.getLong(idx);
      } finally {
        cursor.close();
        cursor.release();
      }
    } finally {
      resolver.release();
      ctx.release();
    }
  }

  void _putString(android.ContentValues values, String key, String? value) {
    if (value == null) return;
    values.put$8(key.toJString(), value.toJString());
  }

  void _putInt(android.ContentValues values, String key, int value) {
    values.put$5(key.toJString(), value.toJInteger());
  }

  int _phoneType(PhoneLabel label) {
    return switch (label) {
      PhoneLabel.home => 1,
      PhoneLabel.mobile => 2,
      PhoneLabel.work => 3,
      PhoneLabel.faxWork => 4,
      PhoneLabel.faxHome => 5,
      PhoneLabel.pager => 6,
      PhoneLabel.custom => 0,
      PhoneLabel.other => 7,
    };
  }

  int _emailType(EmailLabel label) {
    return switch (label) {
      EmailLabel.home => 1,
      EmailLabel.work => 2,
      EmailLabel.custom => 0,
      EmailLabel.other => 3,
    };
  }

  Future<Contact?> _findCreated(Contact seed) async {
    if (seed.phones.isNotEmpty) {
      final page = await search(
        seed.phones.first.number,
        const ContactQuery(fields: ContactFields.detail, pageSize: 5),
      );
      if (page.contacts.isNotEmpty) return page.contacts.first;
    }
    if (seed.displayName != null && seed.displayName!.isNotEmpty) {
      final page = await search(
        seed.displayName!,
        const ContactQuery(fields: ContactFields.detail, pageSize: 5),
      );
      if (page.contacts.isNotEmpty) return page.contacts.first;
    }
    return null;
  }

  Uint8List? _readFully(android.InputStream stream) {
    final chunks = <int>[];
    final buffer = JByteArray(8 * 1024);
    try {
      while (true) {
        final read = stream.read$1(buffer);
        if (read <= 0) break;
        for (var i = 0; i < read; i++) {
          chunks.add(buffer[i]);
        }
      }
    } finally {
      buffer.release();
    }
    if (chunks.isEmpty) return null;
    return Uint8List.fromList(chunks);
  }

  JArray<JString?> _stringArray(List<String> values) {
    final array = JArray(JString.nullableType, values.length);
    for (var i = 0; i < values.length; i++) {
      array[i] = values[i].toJString();
    }
    return array;
  }
}
