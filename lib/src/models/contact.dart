import 'package:flutter/foundation.dart';

import 'contact_event.dart';
import 'email.dart';
import 'name.dart';
import 'organization.dart';
import 'phone.dart';
import 'postal_address.dart';
import 'related_person.dart';
import 'social_profile.dart';
import 'website.dart';

/// An immutable contact record.
///
/// Avatar bytes are intentionally omitted — fetch them via
/// [FlutterContactsPro.getAvatar] to avoid transferring images during list
/// queries.
@immutable
class Contact {
  /// Opaque platform contact id. Empty for contacts not yet persisted.
  final String id;

  /// Best display name for UI lists.
  final String? displayName;

  /// Structured name components.
  final Name? name;

  final List<Phone> phones;
  final List<Email> emails;
  final List<PostalAddress> addresses;
  final Organization? organization;
  final String? note;
  final List<Website> websites;
  final List<SocialProfile> socialProfiles;
  final List<RelatedPerson> relations;
  final List<ContactEvent> events;

  /// Opaque group ids this contact belongs to.
  final List<String> groupIds;

  /// Android starred/favorite; typically `false` when unsupported.
  final bool isFavorite;

  /// Best-effort last-updated timestamp; may be null.
  final DateTime? updatedAt;

  const Contact({
    this.id = '',
    this.displayName,
    this.name,
    this.phones = const [],
    this.emails = const [],
    this.addresses = const [],
    this.organization,
    this.note,
    this.websites = const [],
    this.socialProfiles = const [],
    this.relations = const [],
    this.events = const [],
    this.groupIds = const [],
    this.isFavorite = false,
    this.updatedAt,
  });

  /// Whether this contact has been persisted (non-empty [id]).
  bool get isPersisted => id.isNotEmpty;

  Contact copyWith({
    String? id,
    String? displayName,
    Name? name,
    List<Phone>? phones,
    List<Email>? emails,
    List<PostalAddress>? addresses,
    Organization? organization,
    String? note,
    List<Website>? websites,
    List<SocialProfile>? socialProfiles,
    List<RelatedPerson>? relations,
    List<ContactEvent>? events,
    List<String>? groupIds,
    bool? isFavorite,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      name: name ?? this.name,
      phones: phones ?? this.phones,
      emails: emails ?? this.emails,
      addresses: addresses ?? this.addresses,
      organization: organization ?? this.organization,
      note: note ?? this.note,
      websites: websites ?? this.websites,
      socialProfiles: socialProfiles ?? this.socialProfiles,
      relations: relations ?? this.relations,
      events: events ?? this.events,
      groupIds: groupIds ?? this.groupIds,
      isFavorite: isFavorite ?? this.isFavorite,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact &&
        other.id == id &&
        other.displayName == displayName &&
        other.name == name &&
        listEquals(other.phones, phones) &&
        listEquals(other.emails, emails) &&
        listEquals(other.addresses, addresses) &&
        other.organization == organization &&
        other.note == note &&
        listEquals(other.websites, websites) &&
        listEquals(other.socialProfiles, socialProfiles) &&
        listEquals(other.relations, relations) &&
        listEquals(other.events, events) &&
        listEquals(other.groupIds, groupIds) &&
        other.isFavorite == isFavorite &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        displayName,
        name,
        Object.hashAll(phones),
        Object.hashAll(emails),
        Object.hashAll(addresses),
        organization,
        note,
        Object.hashAll(websites),
        Object.hashAll(socialProfiles),
        Object.hashAll(relations),
        Object.hashAll(events),
        Object.hashAll(groupIds),
        isFavorite,
        updatedAt,
      );

  @override
  String toString() =>
      'Contact(id: $id, displayName: $displayName, phones: ${phones.length}, emails: ${emails.length})';
}
