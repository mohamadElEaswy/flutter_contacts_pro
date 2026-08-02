/// Android Contacts Provider column / MIME constants used by the JNI layer.
///
/// Hardcoded string values match [android.provider.ContactsContract] so we
/// avoid JNI static-field lookups on every query.
abstract final class AndroidContactColumns {
  AndroidContactColumns._();

  static const authority = 'com.android.contacts';

  static const id = '_id';
  static const displayName = 'display_name';
  static const displayNamePrimary = 'display_name';
  static const starred = 'starred';
  static const contactLastUpdatedTimestamp = 'contact_last_updated_timestamp';
  static const photoUri = 'photo_uri';
  static const photoThumbnailUri = 'photo_thumb_uri';
  static const hasPhoneNumber = 'has_phone_number';
  static const lookup = 'lookup';

  static const contactId = 'contact_id';
  static const mimeType = 'mimetype';
  static const data1 = 'data1';
  static const data2 = 'data2';
  static const data3 = 'data3';
  static const data4 = 'data4';
  static const data5 = 'data5';
  static const data6 = 'data6';
  static const data7 = 'data7';
  static const data8 = 'data8';
  static const data9 = 'data9';
  static const data10 = 'data10';
  static const isPrimary = 'is_primary';
  static const isSuperPrimary = 'is_super_primary';

  static const mimeStructuredName =
      'vnd.android.cursor.item/name';
  static const mimePhone = 'vnd.android.cursor.item/phone_v2';
  static const mimeEmail = 'vnd.android.cursor.item/email_v2';
  static const mimePostal = 'vnd.android.cursor.item/postal-address_v2';
  static const mimeOrganization = 'vnd.android.cursor.item/organization';
  static const mimeNote = 'vnd.android.cursor.item/note';
  static const mimeWebsite = 'vnd.android.cursor.item/website';
  static const mimeNickname = 'vnd.android.cursor.item/nickname';
  static const mimeEvent = 'vnd.android.cursor.item/contact_event';
  static const mimeRelation = 'vnd.android.cursor.item/relation';
  static const mimeGroupMembership =
      'vnd.android.cursor.item/group_membership';

  static const permissionRead = 'android.permission.READ_CONTACTS';
  static const permissionWrite = 'android.permission.WRITE_CONTACTS';
}
