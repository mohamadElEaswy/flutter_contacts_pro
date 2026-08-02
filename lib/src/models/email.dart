import 'package:flutter/foundation.dart';

/// Semantic label for an email address.
enum EmailLabel {
  home,
  work,
  other,
  custom,
}

/// An email address on a contact.
@immutable
class Email {
  final String address;
  final EmailLabel label;
  final String? customLabel;
  final bool isPrimary;

  const Email({
    required this.address,
    this.label = EmailLabel.other,
    this.customLabel,
    this.isPrimary = false,
  });

  Email copyWith({
    String? address,
    EmailLabel? label,
    String? customLabel,
    bool? isPrimary,
  }) {
    return Email(
      address: address ?? this.address,
      label: label ?? this.label,
      customLabel: customLabel ?? this.customLabel,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Email &&
        other.address == address &&
        other.label == label &&
        other.customLabel == customLabel &&
        other.isPrimary == isPrimary;
  }

  @override
  int get hashCode => Object.hash(address, label, customLabel, isPrimary);

  @override
  String toString() =>
      'Email(address: $address, label: $label, isPrimary: $isPrimary)';
}
