import 'package:flutter/foundation.dart';

import '../models/contact_fields.dart';
import 'contact_sort.dart';

/// Maximum allowed [ContactQuery.pageSize].
const int kMaxContactPageSize = 500;

/// Default [ContactQuery.pageSize].
const int kDefaultContactPageSize = 50;

/// Options for paginated contact reads and searches.
@immutable
class ContactQuery {
  /// Fields to fetch. Defaults to [ContactFields.list].
  final Set<ContactField> fields;

  /// Page size (clamped to `1..[kMaxContactPageSize]` by the facade).
  final int pageSize;

  /// Opaque token from a previous [ContactPage.nextPageToken]; null = first page.
  final String? pageToken;

  /// Sort order for results.
  final ContactSort sort;

  /// Optional group filter.
  final String? groupId;

  const ContactQuery({
    this.fields = ContactFields.list,
    this.pageSize = kDefaultContactPageSize,
    this.pageToken,
    this.sort = ContactSort.displayNameAsc,
    this.groupId,
  });

  /// Returns a copy with [pageSize] clamped to a valid range.
  ContactQuery normalized() {
    final clamped = pageSize.clamp(1, kMaxContactPageSize);
    if (clamped == pageSize) return this;
    return copyWith(pageSize: clamped);
  }

  ContactQuery copyWith({
    Set<ContactField>? fields,
    int? pageSize,
    String? pageToken,
    ContactSort? sort,
    String? groupId,
    bool clearPageToken = false,
    bool clearGroupId = false,
  }) {
    return ContactQuery(
      fields: fields ?? this.fields,
      pageSize: pageSize ?? this.pageSize,
      pageToken: clearPageToken ? null : (pageToken ?? this.pageToken),
      sort: sort ?? this.sort,
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactQuery &&
        setEquals(other.fields, fields) &&
        other.pageSize == pageSize &&
        other.pageToken == pageToken &&
        other.sort == sort &&
        other.groupId == groupId;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(fields),
        pageSize,
        pageToken,
        sort,
        groupId,
      );

  @override
  String toString() =>
      'ContactQuery(fields: $fields, pageSize: $pageSize, pageToken: $pageToken, sort: $sort, groupId: $groupId)';
}
