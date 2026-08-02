import 'package:flutter/foundation.dart';

/// Kind of change reported by the contacts change stream.
enum ContactChangeType {
  added,
  updated,
  deleted,

  /// Platform signaled a change without a specific contact id.
  unknown,
}

/// A contacts store change notification.
@immutable
class ContactChangeEvent {
  /// The type of change.
  final ContactChangeType type;

  /// Affected contact id when the platform provides one.
  final String? contactId;

  /// When the event was observed (device clock).
  final DateTime timestamp;

  const ContactChangeEvent({
    required this.type,
    this.contactId,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactChangeEvent &&
        other.type == type &&
        other.contactId == contactId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(type, contactId, timestamp);

  @override
  String toString() =>
      'ContactChangeEvent(type: $type, contactId: $contactId, timestamp: $timestamp)';
}
