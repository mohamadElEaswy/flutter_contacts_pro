import 'package:flutter/material.dart';
import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';

/// Drops unpaired UTF-16 surrogates so Flutter text painting won't crash.
String sanitizeUtf16(String input) {
  final units = input.codeUnits;
  if (units.isEmpty) return input;

  final out = <int>[];
  for (var i = 0; i < units.length; i++) {
    final unit = units[i];
    if (unit >= 0xD800 && unit <= 0xDBFF) {
      final next = i + 1 < units.length ? units[i + 1] : null;
      if (next != null && next >= 0xDC00 && next <= 0xDFFF) {
        out
          ..add(unit)
          ..add(next);
        i++;
      } else {
        out.add(0xFFFD);
      }
    } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
      out.add(0xFFFD);
    } else {
      out.add(unit);
    }
  }

  if (out.length == units.length) {
    var unchanged = true;
    for (var i = 0; i < units.length; i++) {
      if (out[i] != units[i]) {
        unchanged = false;
        break;
      }
    }
    if (unchanged) return input;
  }
  return String.fromCharCodes(out);
}

String contactInitials(Contact contact) {
  final name = sanitizeUtf16((contact.displayName ?? contact.id).trim());
  if (name.isEmpty) return '?';

  final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts
      .take(2)
      .map((part) {
        final chars = part.characters;
        if (chars.isEmpty) return '';
        // Avoid indexing code units ([0]) which breaks emoji / surrogate pairs.
        return chars.first.toUpperCase();
      })
      .where((s) => s.isNotEmpty)
      .join();

  return letters.isEmpty ? '?' : letters;
}

String? contactSubtitle(Contact contact) {
  if (contact.phones.isNotEmpty) {
    return sanitizeUtf16(contact.phones.first.number);
  }
  if (contact.emails.isNotEmpty) {
    return sanitizeUtf16(contact.emails.first.address);
  }
  return null;
}

String contactDisplayName(Contact contact) {
  return sanitizeUtf16(contact.displayName ?? contact.id);
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
