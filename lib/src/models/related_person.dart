import 'package:flutter/foundation.dart';

/// Semantic label for a related person.
enum RelatedPersonLabel {
  parent,
  mother,
  father,
  brother,
  sister,
  child,
  friend,
  spouse,
  partner,
  assistant,
  manager,
  other,
  custom,
}

/// A related person entry on a contact.
@immutable
class RelatedPerson {
  final String name;
  final RelatedPersonLabel label;
  final String? customLabel;

  const RelatedPerson({
    required this.name,
    this.label = RelatedPersonLabel.other,
    this.customLabel,
  });

  RelatedPerson copyWith({
    String? name,
    RelatedPersonLabel? label,
    String? customLabel,
  }) {
    return RelatedPerson(
      name: name ?? this.name,
      label: label ?? this.label,
      customLabel: customLabel ?? this.customLabel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelatedPerson &&
        other.name == name &&
        other.label == label &&
        other.customLabel == customLabel;
  }

  @override
  int get hashCode => Object.hash(name, label, customLabel);

  @override
  String toString() => 'RelatedPerson(name: $name, label: $label)';
}
