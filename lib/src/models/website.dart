import 'package:flutter/foundation.dart';

/// Semantic label for a website.
enum WebsiteLabel {
  homepage,
  home,
  work,
  other,
  custom,
}

/// A website URL on a contact.
@immutable
class Website {
  final String url;
  final WebsiteLabel label;
  final String? customLabel;

  const Website({
    required this.url,
    this.label = WebsiteLabel.other,
    this.customLabel,
  });

  Website copyWith({
    String? url,
    WebsiteLabel? label,
    String? customLabel,
  }) {
    return Website(
      url: url ?? this.url,
      label: label ?? this.label,
      customLabel: customLabel ?? this.customLabel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Website &&
        other.url == url &&
        other.label == label &&
        other.customLabel == customLabel;
  }

  @override
  int get hashCode => Object.hash(url, label, customLabel);

  @override
  String toString() => 'Website(url: $url, label: $label)';
}
