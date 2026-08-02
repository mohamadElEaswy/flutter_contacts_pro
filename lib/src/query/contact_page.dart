import 'package:flutter/foundation.dart';

import '../models/contact.dart';

/// One page of contacts from [FlutterContactsPro.getContacts] or search.
@immutable
class ContactPage {
  /// Contacts in this page.
  final List<Contact> contacts;

  /// Token for the next page; null when there are no more results.
  final String? nextPageToken;

  /// Best-effort total count; may be null (especially on iOS).
  final int? estimatedTotal;

  const ContactPage({
    required this.contacts,
    this.nextPageToken,
    this.estimatedTotal,
  });

  /// Whether another page can be requested.
  bool get hasMore => nextPageToken != null;

  /// An empty page with no further results.
  static const ContactPage empty = ContactPage(contacts: []);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactPage &&
        listEquals(other.contacts, contacts) &&
        other.nextPageToken == nextPageToken &&
        other.estimatedTotal == estimatedTotal;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(contacts),
        nextPageToken,
        estimatedTotal,
      );

  @override
  String toString() =>
      'ContactPage(contacts: ${contacts.length}, nextPageToken: $nextPageToken, estimatedTotal: $estimatedTotal)';
}
