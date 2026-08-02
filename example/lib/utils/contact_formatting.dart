import 'package:flutter/material.dart';
import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';

String contactInitials(Contact contact) {
  final name = (contact.displayName ?? contact.id).trim();
  if (name.isEmpty) return '?';
  final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}

String? contactSubtitle(Contact contact) {
  if (contact.phones.isNotEmpty) return contact.phones.first.number;
  if (contact.emails.isNotEmpty) return contact.emails.first.address;
  return null;
}

Color avatarColorFor(String key, ColorScheme scheme) {
  final palette = [
    scheme.primary,
    scheme.tertiary,
    scheme.secondary,
    const Color(0xFFB45309),
    const Color(0xFF1D4ED8),
    const Color(0xFFBE123C),
  ];
  return palette[key.hashCode.abs() % palette.length];
}
