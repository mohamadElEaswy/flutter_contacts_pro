---
name: flutter-contacts-pro
description: >-
  Guides agents building features with flutter_contacts_pro: Dart models,
  FlutterContactsPro service API, field masks, pagination, permissions,
  Android registration, FakeContactsPlatform tests, and performance rules.
  Use when editing this plugin, integrating contacts in an app, writing
  contacts UI/tests, or when the user mentions flutter_contacts_pro, ContactQuery,
  ContactFields, or JNIGEN contacts.
---

# flutter_contacts_pro

## When to use

- Implementing or extending this plugin’s Dart API
- Integrating contacts into an app that depends on this package
- Writing unit/widget tests with `FakeContactsPlatform`
- Wiring Android startup (`FlutterContactsProAndroid.register`)

## Non-negotiable rules

1. **Never put avatar bytes on `Contact`** — use `getAvatar` / `hasAvatar`
2. **Always paginate list UIs** — `ContactQuery(pageSize: …)` + `nextPageToken`
3. **Use field masks** — `ContactFields.minimal` / `.list` / `.detail` (or a custom `Set<ContactField>`)
4. **Register Android** before `FlutterContactsPro.instance` on Android
5. **Inject `ContactsPlatform` in tests** — do not hit device contacts in unit tests
6. **Do not hand-edit** `lib/src/android/bindings/*.g.dart`

## Imports

```dart
import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';
import 'package:flutter_contacts_pro/android.dart';   // Android only
import 'package:flutter_contacts_pro/testing.dart';   // FakeContactsPlatform
```

## Android bootstrap

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    FlutterContactsProAndroid.register();
  }
  runApp(const MyApp());
}
```

## Canonical usage patterns

### Permission then list

```dart
final api = FlutterContactsPro.instance;
final status = await api.requestPermission();
if (status != PermissionStatus.granted &&
    status != PermissionStatus.limited) {
  await api.openSettings();
  return;
}

ContactPage page = await api.getContacts(
  query: const ContactQuery(fields: ContactFields.list, pageSize: 50),
);
while (page.hasMore) {
  page = await api.getContacts(
    query: ContactQuery(
      fields: ContactFields.list,
      pageSize: 50,
      pageToken: page.nextPageToken,
    ),
  );
}
```

### Detail + avatar

```dart
final contact = await api.getContact(id, fields: ContactFields.detail);
final bytes = await api.getAvatar(id); // AvatarSize.thumbnail by default
```

### Create / update / delete

```dart
final created = await api.createContact(
  Contact(
    displayName: 'Ada Lovelace',
    phones: [Phone(number: '+1 555 0100', label: PhoneLabel.mobile)],
  ),
);
await api.updateContact(created.copyWith(note: 'Mathematician'));
await api.deleteContact(created.id);
```

### Change stream

```dart
api.onContactsChanged.listen((ContactChangeEvent e) {
  // Platforms may send ContactChangeType.unknown with null contactId
  api.clearCache(); // safe no-op until cache lands
});
```

### Tests

```dart
final fake = FakeContactsPlatform(
  contacts: [Contact(id: '1', displayName: 'Ada')],
);
final api = FlutterContactsPro(platform: fake);
// …
fake.dispose();
```

## Architecture map

| Layer | Path |
|-------|------|
| Public barrel | `lib/flutter_contacts_pro.dart` |
| Facade | `lib/src/api/flutter_contacts_pro.dart` |
| Models | `lib/src/models/` |
| Query | `lib/src/query/` |
| Errors | `lib/src/errors/contacts_exception.dart` |
| Platform interface | `lib/src/platform/contacts_platform.dart` |
| Android impl | `lib/src/android/android_contacts_platform.dart` |
| Android register | `lib/android.dart` |
| Fake | `lib/testing.dart` |
| JNIGEN config | `jnigen.yaml` |

```text
FlutterContactsPro → ContactsPlatform
  ├─ AndroidContactsPlatform (JNIGEN) after register()
  ├─ UnimplementedContactsPlatform (default)
  └─ FakeContactsPlatform (tests)
```

## Feature checklist (Flutter API)

- [x] Permissions: get / request / openSettings (`PermissionMode`, `PermissionStatus`)
- [x] `getContacts` + `ContactQuery` pagination + sort + field mask
- [x] `search` (empty → empty page)
- [x] `getContact` / `getAvatar` / `hasAvatar`
- [x] CRUD: create / update / delete / deleteContacts
- [x] Groups API surface (Android impl may still be unimplemented)
- [x] `onContactsChanged` stream
- [x] Sealed `ContactsException` hierarchy
- [x] `FakeContactsPlatform`
- [ ] iOS Contacts.framework
- [ ] Dart LRU cache ( `clearCache` reserved )

## Agent do / don’t

**Do**
- Prefer `ContactFields.list` for lists; `detail` only for detail screens
- Catch sealed exceptions with `on PermissionDeniedException` etc.
- Keep IDs opaque strings; never invent Android raw-contact IDs in app code
- After changing `jnigen.yaml`, regenerate with `./tool/generate_android_bindings.sh` (example APK must have been built once)

**Don’t**
- Add photo fields to `Contact`
- Fetch all contacts without pagination
- Import `lib/src/android/bindings/` from app code
- Edit the generated bindings file
- Assume group CRUD works on device until implemented (catch `UnimplementedError` or feature-flag)

## Deeper reference

For full model/field tables and exception list, see [reference.md](reference.md) or the package [README.md](../../../README.md).
