import 'package:flutter/foundation.dart';

/// A contacts group / label.
@immutable
class ContactGroup {
  /// Opaque platform group id.
  final String id;

  /// Display name of the group.
  final String name;

  /// Best-effort member count; may be null when unknown.
  final int? memberCount;

  const ContactGroup({
    required this.id,
    required this.name,
    this.memberCount,
  });

  ContactGroup copyWith({
    String? id,
    String? name,
    int? memberCount,
  }) {
    return ContactGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactGroup &&
        other.id == id &&
        other.name == name &&
        other.memberCount == memberCount;
  }

  @override
  int get hashCode => Object.hash(id, name, memberCount);

  @override
  String toString() =>
      'ContactGroup(id: $id, name: $name, memberCount: $memberCount)';
}
