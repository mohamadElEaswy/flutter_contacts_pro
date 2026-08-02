import 'package:flutter/foundation.dart';

/// A social-network profile linked to a contact.
@immutable
class SocialProfile {
  final String? service;
  final String? userName;
  final String? userIdentifier;
  final String? url;
  final String? label;

  const SocialProfile({
    this.service,
    this.userName,
    this.userIdentifier,
    this.url,
    this.label,
  });

  SocialProfile copyWith({
    String? service,
    String? userName,
    String? userIdentifier,
    String? url,
    String? label,
  }) {
    return SocialProfile(
      service: service ?? this.service,
      userName: userName ?? this.userName,
      userIdentifier: userIdentifier ?? this.userIdentifier,
      url: url ?? this.url,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialProfile &&
        other.service == service &&
        other.userName == userName &&
        other.userIdentifier == userIdentifier &&
        other.url == url &&
        other.label == label;
  }

  @override
  int get hashCode =>
      Object.hash(service, userName, userIdentifier, url, label);

  @override
  String toString() =>
      'SocialProfile(service: $service, userName: $userName, url: $url)';
}
