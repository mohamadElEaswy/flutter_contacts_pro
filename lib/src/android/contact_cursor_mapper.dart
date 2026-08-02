import '../models/contact.dart';
import '../models/contact_event.dart';
import '../models/contact_fields.dart';
import '../models/email.dart';
import '../models/name.dart';
import '../models/organization.dart';
import '../models/phone.dart';
import '../models/postal_address.dart';
import '../models/related_person.dart';
import '../models/website.dart';
import 'android_contact_columns.dart';

/// Builds a [Contact] from row maps (no JNI) so unit tests can run on host.
class ContactCursorMapper {
  const ContactCursorMapper();

  /// Maps a Contacts table summary row.
  Contact fromContactsRow(
    Map<String, Object?> row, {
    Set<ContactField> fields = ContactFields.list,
  }) {
    final id = '${row[AndroidContactColumns.id] ?? ''}';
    final displayName = fields.contains(ContactField.displayName)
        ? row[AndroidContactColumns.displayName]?.toString()
        : null;
    final isFavorite = fields.contains(ContactField.isFavorite)
        ? (row[AndroidContactColumns.starred] as int? ?? 0) == 1
        : false;
    final updatedAt = fields.contains(ContactField.updatedAt)
        ? _parseTimestamp(row[AndroidContactColumns.contactLastUpdatedTimestamp])
        : null;

    return Contact(
      id: id,
      displayName: displayName,
      isFavorite: isFavorite,
      updatedAt: updatedAt,
    );
  }

  /// Merges Contacts summary [base] with Data-table [dataRows].
  Contact mergeDataRows(
    Contact base,
    List<Map<String, Object?>> dataRows, {
    required Set<ContactField> fields,
  }) {
    Name? name = fields.contains(ContactField.name) ? base.name : null;
    final phones = <Phone>[];
    final emails = <Email>[];
    final addresses = <PostalAddress>[];
    Organization? organization;
    String? note;
    final websites = <Website>[];
    final relations = <RelatedPerson>[];
    final events = <ContactEvent>[];
    final groupIds = <String>[];

    for (final row in dataRows) {
      final mime = row[AndroidContactColumns.mimeType]?.toString();
      switch (mime) {
        case AndroidContactColumns.mimeStructuredName:
          if (fields.contains(ContactField.name)) {
            name = Name(
              givenName: _str(row, AndroidContactColumns.data2),
              familyName: _str(row, AndroidContactColumns.data3),
              prefix: _str(row, AndroidContactColumns.data4),
              middleName: _str(row, AndroidContactColumns.data5),
              suffix: _str(row, AndroidContactColumns.data6),
              phoneticGivenName: _str(row, AndroidContactColumns.data7),
              phoneticMiddleName: _str(row, AndroidContactColumns.data8),
              phoneticFamilyName: _str(row, AndroidContactColumns.data9),
            );
          }
        case AndroidContactColumns.mimeNickname:
          if (fields.contains(ContactField.name)) {
            final nick = _str(row, AndroidContactColumns.data1);
            name = (name ?? const Name()).copyWith(nickname: nick);
          }
        case AndroidContactColumns.mimePhone:
          if (fields.contains(ContactField.phones)) {
            final number = _str(row, AndroidContactColumns.data1);
            if (number != null && number.isNotEmpty) {
              phones.add(
                Phone(
                  number: number,
                  label: _phoneLabel(row[AndroidContactColumns.data2] as int?),
                  customLabel: _str(row, AndroidContactColumns.data3),
                  isPrimary: _isPrimary(row),
                ),
              );
            }
          }
        case AndroidContactColumns.mimeEmail:
          if (fields.contains(ContactField.emails)) {
            final address = _str(row, AndroidContactColumns.data1);
            if (address != null && address.isNotEmpty) {
              emails.add(
                Email(
                  address: address,
                  label: _emailLabel(row[AndroidContactColumns.data2] as int?),
                  customLabel: _str(row, AndroidContactColumns.data3),
                  isPrimary: _isPrimary(row),
                ),
              );
            }
          }
        case AndroidContactColumns.mimePostal:
          if (fields.contains(ContactField.addresses)) {
            addresses.add(
              PostalAddress(
                street: _str(row, AndroidContactColumns.data4),
                poBox: _str(row, AndroidContactColumns.data5),
                neighborhood: _str(row, AndroidContactColumns.data6),
                city: _str(row, AndroidContactColumns.data7),
                region: _str(row, AndroidContactColumns.data8),
                postcode: _str(row, AndroidContactColumns.data9),
                country: _str(row, AndroidContactColumns.data10),
                label: _postalLabel(row[AndroidContactColumns.data2] as int?),
                customLabel: _str(row, AndroidContactColumns.data3),
                isPrimary: _isPrimary(row),
              ),
            );
          }
        case AndroidContactColumns.mimeOrganization:
          if (fields.contains(ContactField.organization)) {
            organization = Organization(
              company: _str(row, AndroidContactColumns.data1),
              jobTitle: _str(row, AndroidContactColumns.data4),
              department: _str(row, AndroidContactColumns.data5),
              phoneticCompany: _str(row, AndroidContactColumns.data8),
            );
          }
        case AndroidContactColumns.mimeNote:
          if (fields.contains(ContactField.note)) {
            note = _str(row, AndroidContactColumns.data1);
          }
        case AndroidContactColumns.mimeWebsite:
          if (fields.contains(ContactField.websites)) {
            final url = _str(row, AndroidContactColumns.data1);
            if (url != null && url.isNotEmpty) {
              websites.add(
                Website(
                  url: url,
                  label: _websiteLabel(row[AndroidContactColumns.data2] as int?),
                  customLabel: _str(row, AndroidContactColumns.data3),
                ),
              );
            }
          }
        case AndroidContactColumns.mimeEvent:
          if (fields.contains(ContactField.events)) {
            final parsed = _parseEventDate(_str(row, AndroidContactColumns.data1));
            if (parsed != null) {
              events.add(
                ContactEvent(
                  year: parsed.$1,
                  month: parsed.$2,
                  day: parsed.$3,
                  label: _eventLabel(row[AndroidContactColumns.data2] as int?),
                  customLabel: _str(row, AndroidContactColumns.data3),
                ),
              );
            }
          }
        case AndroidContactColumns.mimeRelation:
          if (fields.contains(ContactField.relations)) {
            final related = _str(row, AndroidContactColumns.data1);
            if (related != null && related.isNotEmpty) {
              relations.add(
                RelatedPerson(
                  name: related,
                  label: RelatedPersonLabel.other,
                  customLabel: _str(row, AndroidContactColumns.data3),
                ),
              );
            }
          }
        case AndroidContactColumns.mimeGroupMembership:
          if (fields.contains(ContactField.groupIds)) {
            final gid = row[AndroidContactColumns.data1]?.toString();
            if (gid != null && gid.isNotEmpty) groupIds.add(gid);
          }
      }
    }

    return Contact(
      id: base.id,
      displayName: fields.contains(ContactField.displayName)
          ? base.displayName
          : null,
      name: name,
      phones: fields.contains(ContactField.phones) ? phones : const [],
      emails: fields.contains(ContactField.emails) ? emails : const [],
      addresses: fields.contains(ContactField.addresses) ? addresses : const [],
      organization:
          fields.contains(ContactField.organization) ? organization : null,
      note: fields.contains(ContactField.note) ? note : null,
      websites: fields.contains(ContactField.websites) ? websites : const [],
      relations: fields.contains(ContactField.relations) ? relations : const [],
      events: fields.contains(ContactField.events) ? events : const [],
      groupIds: fields.contains(ContactField.groupIds) ? groupIds : const [],
      isFavorite:
          fields.contains(ContactField.isFavorite) ? base.isFavorite : false,
      updatedAt: fields.contains(ContactField.updatedAt) ? base.updatedAt : null,
    );
  }

  static String? _str(Map<String, Object?> row, String key) {
    final v = row[key];
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  static bool _isPrimary(Map<String, Object?> row) {
    final primary = row[AndroidContactColumns.isPrimary] as int? ?? 0;
    final superPrimary = row[AndroidContactColumns.isSuperPrimary] as int? ?? 0;
    return primary == 1 || superPrimary == 1;
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value == null) return null;
    final ms = value is int ? value : int.tryParse(value.toString());
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Android stores events as `--MM-DD` or `YYYY-MM-DD`.
  static (int?, int, int)? _parseEventDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'^(?:(\d{4})|--)?-?(\d{1,2})-(\d{1,2})$').firstMatch(raw);
    if (match == null) {
      // Fallback: split handling leading empty year for `--MM-DD`.
      final normalized = raw.startsWith('--') ? '0${raw.substring(1)}' : raw;
      final parts = normalized.split('-');
      if (parts.length < 3) return null;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (month == null || day == null) return null;
      return (year == 0 ? null : year, month, day);
    }
    final year = match.group(1) == null ? null : int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (month == null || day == null) return null;
    return (year, month, day);
  }

  static PhoneLabel _phoneLabel(int? type) {
    return switch (type) {
      1 => PhoneLabel.home,
      2 => PhoneLabel.mobile,
      3 => PhoneLabel.work,
      4 => PhoneLabel.faxWork,
      5 => PhoneLabel.faxHome,
      6 => PhoneLabel.pager,
      0 => PhoneLabel.custom,
      _ => PhoneLabel.other,
    };
  }

  static EmailLabel _emailLabel(int? type) {
    return switch (type) {
      1 => EmailLabel.home,
      2 => EmailLabel.work,
      0 => EmailLabel.custom,
      _ => EmailLabel.other,
    };
  }

  static PostalAddressLabel _postalLabel(int? type) {
    return switch (type) {
      1 => PostalAddressLabel.home,
      2 => PostalAddressLabel.work,
      0 => PostalAddressLabel.custom,
      _ => PostalAddressLabel.other,
    };
  }

  static WebsiteLabel _websiteLabel(int? type) {
    return switch (type) {
      1 => WebsiteLabel.homepage,
      4 => WebsiteLabel.home,
      5 => WebsiteLabel.work,
      0 => WebsiteLabel.custom,
      _ => WebsiteLabel.other,
    };
  }

  static ContactEventLabel _eventLabel(int? type) {
    return switch (type) {
      3 => ContactEventLabel.birthday,
      1 => ContactEventLabel.anniversary,
      0 => ContactEventLabel.custom,
      _ => ContactEventLabel.other,
    };
  }
}
