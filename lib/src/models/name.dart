import 'package:flutter/foundation.dart';

/// Structured person name components.
@immutable
class Name {
  final String? givenName;
  final String? middleName;
  final String? familyName;
  final String? prefix;
  final String? suffix;
  final String? phoneticGivenName;
  final String? phoneticMiddleName;
  final String? phoneticFamilyName;
  final String? nickname;

  const Name({
    this.givenName,
    this.middleName,
    this.familyName,
    this.prefix,
    this.suffix,
    this.phoneticGivenName,
    this.phoneticMiddleName,
    this.phoneticFamilyName,
    this.nickname,
  });

  Name copyWith({
    String? givenName,
    String? middleName,
    String? familyName,
    String? prefix,
    String? suffix,
    String? phoneticGivenName,
    String? phoneticMiddleName,
    String? phoneticFamilyName,
    String? nickname,
  }) {
    return Name(
      givenName: givenName ?? this.givenName,
      middleName: middleName ?? this.middleName,
      familyName: familyName ?? this.familyName,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      phoneticGivenName: phoneticGivenName ?? this.phoneticGivenName,
      phoneticMiddleName: phoneticMiddleName ?? this.phoneticMiddleName,
      phoneticFamilyName: phoneticFamilyName ?? this.phoneticFamilyName,
      nickname: nickname ?? this.nickname,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Name &&
        other.givenName == givenName &&
        other.middleName == middleName &&
        other.familyName == familyName &&
        other.prefix == prefix &&
        other.suffix == suffix &&
        other.phoneticGivenName == phoneticGivenName &&
        other.phoneticMiddleName == phoneticMiddleName &&
        other.phoneticFamilyName == phoneticFamilyName &&
        other.nickname == nickname;
  }

  @override
  int get hashCode => Object.hash(
        givenName,
        middleName,
        familyName,
        prefix,
        suffix,
        phoneticGivenName,
        phoneticMiddleName,
        phoneticFamilyName,
        nickname,
      );

  @override
  String toString() =>
      'Name(givenName: $givenName, middleName: $middleName, familyName: $familyName)';
}
