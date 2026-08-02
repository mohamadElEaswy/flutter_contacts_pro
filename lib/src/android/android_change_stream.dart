import 'package:flutter/services.dart';

import '../models/contact_change.dart';

/// Bridges the native ContentObserver EventChannel to Dart.
class AndroidChangeStream {
  AndroidChangeStream({
    EventChannel? channel,
  }) : _channel =
            channel ?? const EventChannel('flutter_contacts_pro/changes');

  final EventChannel _channel;

  Stream<ContactChangeEvent> watch() {
    return _channel.receiveBroadcastStream().map((event) {
      final map = Map<Object?, Object?>.from(event as Map);
      final typeName = map['type']?.toString() ?? 'unknown';
      final type = switch (typeName) {
        'added' => ContactChangeType.added,
        'updated' => ContactChangeType.updated,
        'deleted' => ContactChangeType.deleted,
        _ => ContactChangeType.unknown,
      };
      final id = map['contactId']?.toString();
      final ms = map['timestampMs'];
      final timestamp = ms is int
          ? DateTime.fromMillisecondsSinceEpoch(ms)
          : DateTime.now();
      return ContactChangeEvent(
        type: type,
        contactId: (id == null || id.isEmpty) ? null : id,
        timestamp: timestamp,
      );
    });
  }
}
