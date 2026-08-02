import 'package:flutter/foundation.dart';

/// Semantic label for a phone number.
enum PhoneLabel {
  mobile,
  home,
  work,
  faxHome,
  faxWork,
  pager,
  other,
  custom,
}

/// A phone number on a contact.
@immutable
class Phone {
  final String number;
  final PhoneLabel label;
  final String? customLabel;
  final bool isPrimary;

  const Phone({
    required this.number,
    this.label = PhoneLabel.other,
    this.customLabel,
    this.isPrimary = false,
  });

  Phone copyWith({
    String? number,
    PhoneLabel? label,
    String? customLabel,
    bool? isPrimary,
  }) {
    return Phone(
      number: number ?? this.number,
      label: label ?? this.label,
      customLabel: customLabel ?? this.customLabel,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Phone &&
        other.number == number &&
        other.label == label &&
        other.customLabel == customLabel &&
        other.isPrimary == isPrimary;
  }

  @override
  int get hashCode => Object.hash(number, label, customLabel, isPrimary);

  @override
  String toString() =>
      'Phone(number: $number, label: $label, isPrimary: $isPrimary)';
}
