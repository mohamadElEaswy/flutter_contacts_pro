import 'package:flutter/foundation.dart';

/// Semantic label for a postal address.
enum PostalAddressLabel {
  home,
  work,
  other,
  custom,
}

/// A postal address on a contact.
@immutable
class PostalAddress {
  final String? street;
  final String? city;
  final String? region;
  final String? postcode;
  final String? country;
  final String? neighborhood;
  final String? poBox;
  final PostalAddressLabel label;
  final String? customLabel;
  final bool isPrimary;

  const PostalAddress({
    this.street,
    this.city,
    this.region,
    this.postcode,
    this.country,
    this.neighborhood,
    this.poBox,
    this.label = PostalAddressLabel.other,
    this.customLabel,
    this.isPrimary = false,
  });

  PostalAddress copyWith({
    String? street,
    String? city,
    String? region,
    String? postcode,
    String? country,
    String? neighborhood,
    String? poBox,
    PostalAddressLabel? label,
    String? customLabel,
    bool? isPrimary,
  }) {
    return PostalAddress(
      street: street ?? this.street,
      city: city ?? this.city,
      region: region ?? this.region,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      neighborhood: neighborhood ?? this.neighborhood,
      poBox: poBox ?? this.poBox,
      label: label ?? this.label,
      customLabel: customLabel ?? this.customLabel,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostalAddress &&
        other.street == street &&
        other.city == city &&
        other.region == region &&
        other.postcode == postcode &&
        other.country == country &&
        other.neighborhood == neighborhood &&
        other.poBox == poBox &&
        other.label == label &&
        other.customLabel == customLabel &&
        other.isPrimary == isPrimary;
  }

  @override
  int get hashCode => Object.hash(
        street,
        city,
        region,
        postcode,
        country,
        neighborhood,
        poBox,
        label,
        customLabel,
        isPrimary,
      );

  @override
  String toString() =>
      'PostalAddress(street: $street, city: $city, region: $region, postcode: $postcode, country: $country)';
}
