/// Production-grade Flutter contacts plugin — Dart API.
///
/// Domain models and the [FlutterContactsPro] service surface. Native
/// implementations (Pigeon / JNIGEN / Contacts.framework) land in later phases.
library;

export 'src/api/flutter_contacts_pro.dart';
export 'src/errors/contacts_exception.dart';
export 'src/models/avatar_size.dart';
export 'src/models/contact.dart';
export 'src/models/contact_change.dart';
export 'src/models/contact_event.dart';
export 'src/models/contact_fields.dart';
export 'src/models/contact_group.dart';
export 'src/models/email.dart';
export 'src/models/name.dart';
export 'src/models/organization.dart';
export 'src/models/permission_status.dart';
export 'src/models/phone.dart';
export 'src/models/postal_address.dart';
export 'src/models/related_person.dart';
export 'src/models/social_profile.dart';
export 'src/models/website.dart';
export 'src/platform/contacts_platform.dart';
export 'src/query/contact_page.dart';
export 'src/query/contact_query.dart';
export 'src/query/contact_sort.dart';
