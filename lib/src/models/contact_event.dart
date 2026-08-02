import 'package:flutter/foundation.dart';

/// Kind of calendar event attached to a contact.
enum ContactEventLabel {
  birthday,
  anniversary,
  other,
  custom,
}

/// A date-based event on a contact (birthday, anniversary, etc.).
@immutable
class ContactEvent {
  final int? year;
  final int month;
  final int day;
  final ContactEventLabel label;
  final String? customLabel;

  const ContactEvent({
    this.year,
    required this.month,
    required this.day,
    this.label = ContactEventLabel.other,
    this.customLabel,
  });

  ContactEvent copyWith({
    int? year,
    int? month,
    int? day,
    ContactEventLabel? label,
    String? customLabel,
  }) {
    return ContactEvent(
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      label: label ?? this.label,
      customLabel: customLabel ?? this.customLabel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactEvent &&
        other.year == year &&
        other.month == month &&
        other.day == day &&
        other.label == label &&
        other.customLabel == customLabel;
  }

  @override
  int get hashCode => Object.hash(year, month, day, label, customLabel);

  @override
  String toString() =>
      'ContactEvent(year: $year, month: $month, day: $day, label: $label)';
}
