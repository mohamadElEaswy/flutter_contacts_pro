/// Base exception for all contacts plugin failures.
sealed class ContactsException implements Exception {
  /// Human-readable description of the failure.
  final String message;

  const ContactsException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a contacts operation requires permission that was not granted.
final class PermissionDeniedException extends ContactsException {
  /// The permission mode that was denied, if known.
  final String? mode;

  const PermissionDeniedException(
    super.message, {
    this.mode,
  });
}

/// Thrown when a contact id does not exist on the device.
final class ContactNotFoundException extends ContactsException {
  /// The contact id that was not found.
  final String contactId;

  const ContactNotFoundException(
    this.contactId, {
    String? message,
  }) : super(message ?? 'Contact not found: $contactId');
}

/// Thrown when a contact payload is incomplete or invalid for create/update.
final class InvalidContactException extends ContactsException {
  const InvalidContactException(super.message);
}

/// Thrown when a group id does not exist on the device.
final class GroupNotFoundException extends ContactsException {
  /// The group id that was not found.
  final String groupId;

  const GroupNotFoundException(
    this.groupId, {
    String? message,
  }) : super(message ?? 'Group not found: $groupId');
}

/// Wraps an unexpected platform/native error.
final class PlatformContactsException extends ContactsException {
  /// Platform-specific error code.
  final String code;

  /// Optional native details.
  final Object? details;

  const PlatformContactsException(
    this.code,
    super.message, {
    this.details,
  });

  @override
  String toString() => 'PlatformContactsException($code): $message';
}
