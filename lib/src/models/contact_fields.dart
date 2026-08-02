/// Selectable fields for partial contact fetching.
///
/// Photos are intentionally excluded — use [FlutterContactsPro.getAvatar].
enum ContactField {
  id,
  displayName,
  name,
  phones,
  emails,
  addresses,
  organization,
  note,
  websites,
  socialProfiles,
  relations,
  events,
  groupIds,
  isFavorite,
  updatedAt,
}

/// Common field-mask presets for list and detail UIs.
abstract final class ContactFields {
  ContactFields._();

  /// Minimal mask for identity-only lists.
  static const Set<ContactField> minimal = {
    ContactField.id,
    ContactField.displayName,
  };

  /// Default mask for contact list rows.
  static const Set<ContactField> list = {
    ContactField.id,
    ContactField.displayName,
    ContactField.phones,
    ContactField.emails,
  };

  /// All supported fields except avatars.
  static const Set<ContactField> detail = {
    ContactField.id,
    ContactField.displayName,
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
    ContactField.isFavorite,
    ContactField.updatedAt,
  };
}
