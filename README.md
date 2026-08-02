# flutter_contacts_pro

High-performance, strongly-typed Flutter contacts plugin for Android and iOS.

**Flutter-side focus:** a clean Dart API with immutable models, field masks, pagination, and permissions — so list UIs stay fast even with 1000+ contacts. Avatars are never bundled into list fetches.

| Platform | Status |
|----------|--------|
| Android | JNIGEN + ContactsContract (register via `android.dart`) |
| iOS | API ready; native `Contacts.framework` pending |

---

## Install

```yaml
dependencies:
  flutter_contacts_pro:
    path: ../flutter_contacts_pro   # or your pub.dev / git ref
```

```dart
import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';
```

### Android registration

Call once at startup before using `FlutterContactsPro.instance`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts_pro/android.dart';
import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    FlutterContactsProAndroid.register();
  }
  runApp(const MyApp());
}
```

Manifest permissions (also declared by the plugin):

```xml
<uses-permission android:name="android.permission.READ_CONTACTS" />
<uses-permission android:name="android.permission.WRITE_CONTACTS" />
```

---

## Quick start

```dart
final api = FlutterContactsPro.instance;

// 1) Permission
final status = await api.requestPermission(); // or PermissionMode.readWrite
if (status != PermissionStatus.granted &&
    status != PermissionStatus.limited) {
  await api.openSettings();
  return;
}

// 2) Paginated list (no photos)
final page = await api.getContacts(
  query: const ContactQuery(
    fields: ContactFields.list,
    pageSize: 50,
  ),
);

// 3) Detail + avatar on demand
final full = await api.getContact(
  page.contacts.first.id,
  fields: ContactFields.detail,
);
final thumb = await api.getAvatar(full!.id); // Uint8List?

// 4) Observe store changes
api.onContactsChanged.listen((e) {
  // e.type, e.contactId?, e.timestamp
});
```

---

## Public entrypoints

| Import | Purpose |
|--------|---------|
| `package:flutter_contacts_pro/flutter_contacts_pro.dart` | Models, queries, exceptions, `FlutterContactsPro`, `ContactsPlatform` |
| `package:flutter_contacts_pro/android.dart` | `FlutterContactsProAndroid.register()` |
| `package:flutter_contacts_pro/testing.dart` | `FakeContactsPlatform` for unit/widget tests |

---

## Service API — `FlutterContactsPro`

Prefer **`FlutterContactsPro.instance`**. Inject a platform in tests:

```dart
FlutterContactsPro(platform: FakeContactsPlatform(...));
```

### Permissions

| Method | Description |
|--------|-------------|
| `getPermissionStatus({PermissionMode mode})` | Current status without prompting |
| `requestPermission({PermissionMode mode})` | Shows system prompt when allowed |
| `openSettings()` | Opens app settings; returns `bool` |

**`PermissionMode`:** `read` · `readWrite`

**`PermissionStatus`:** `granted` · `limited` · `denied` · `permanentlyDenied` · `restricted` · `unknown`

- Android maps to `READ_CONTACTS` / `WRITE_CONTACTS`
- iOS can report `limited` (partial access)

### Read

| Method | Description |
|--------|-------------|
| `getContacts({ContactQuery query})` | Paginated contacts; **never** includes avatar bytes |
| `search(String query, {ContactQuery? options})` | Search; empty/whitespace → empty `ContactPage` |
| `getContact(String id, {Set<ContactField>? fields})` | One contact or `null`; default fields = `ContactFields.detail` |
| `getAvatar(String id, {AvatarSize size})` | `Uint8List?` — `thumbnail` (default) or `full` |
| `hasAvatar(String id)` | Whether a photo exists |

Empty `id` on get/avatar throws `InvalidContactException`.

### Write

| Method | Description |
|--------|-------------|
| `createContact(Contact contact)` | Inserts; returns persisted contact with `id` |
| `updateContact(Contact contact)` | Requires non-empty `id` |
| `deleteContact(String id)` | Deletes one contact |
| `deleteContacts(List<String> ids)` | Batch delete; **not** transactional; empty ids ignored |

### Groups (API surface)

| Method | Description |
|--------|-------------|
| `getGroups()` | List groups |
| `createGroup(String name)` | Create (name trimmed; blank → `InvalidContactException`) |
| `deleteGroup(String id)` | Delete group |
| `addContactsToGroup(groupId, contactIds)` | Membership add |
| `removeContactsFromGroup(groupId, contactIds)` | Membership remove |

> On Android today, group methods may throw `UnimplementedError` until groups CRUD is wired. Types and facade are stable for apps to call behind feature flags.

### Observation & cache

| API | Description |
|-----|-------------|
| `onContactsChanged` | `Stream<ContactChangeEvent>` — may emit `unknown` with null `contactId` (coarse reload) |
| `clearCache()` | Clears Dart-side cache (no-op until LRU lands; safe to call) |

---

## Query, pagination & field masks

### `ContactQuery`

| Field | Default | Notes |
|-------|---------|--------|
| `fields` | `ContactFields.list` | What to fetch |
| `pageSize` | `50` | Clamped to `1…500` (`kMaxContactPageSize`) |
| `pageToken` | `null` | Opaque; from previous `ContactPage.nextPageToken` |
| `sort` | `displayNameAsc` | See `ContactSort` |
| `groupId` | `null` | Optional filter |

Helpers: `normalized()`, `copyWith(...)`.

### `ContactSort`

- `displayNameAsc`
- `displayNameDesc`
- `updatedAtDesc`

### `ContactPage`

| Field | Meaning |
|-------|---------|
| `contacts` | This page |
| `nextPageToken` | `null` ⇒ end |
| `estimatedTotal` | Best-effort; may be null on some platforms |
| `hasMore` | `nextPageToken != null` |
| `ContactPage.empty` | Empty page constant |

### `ContactField` / presets

Photos are **not** in the mask — always use `getAvatar`.

| Preset | Fields |
|--------|--------|
| `ContactFields.minimal` | `id`, `displayName` |
| `ContactFields.list` | + `phones`, `emails` |
| `ContactFields.detail` | All fields except avatars |

Individual: `id`, `displayName`, `name`, `phones`, `emails`, `addresses`, `organization`, `note`, `websites`, `socialProfiles`, `relations`, `events`, `groupIds`, `isFavorite`, `updatedAt`.

---

## Models

All domain types are **immutable** with `==` / `hashCode` and (where useful) `copyWith`.

### `Contact`

| Property | Type | Notes |
|----------|------|--------|
| `id` | `String` | Opaque; empty = not persisted |
| `displayName` | `String?` | List UI title |
| `name` | `Name?` | Structured name |
| `phones` | `List<Phone>` | |
| `emails` | `List<Email>` | |
| `addresses` | `List<PostalAddress>` | |
| `organization` | `Organization?` | |
| `note` | `String?` | |
| `websites` | `List<Website>` | |
| `socialProfiles` | `List<SocialProfile>` | |
| `relations` | `List<RelatedPerson>` | |
| `events` | `List<ContactEvent>` | Birthday / anniversary / custom |
| `groupIds` | `List<String>` | |
| `isFavorite` | `bool` | Android starred; often false elsewhere |
| `updatedAt` | `DateTime?` | Best-effort |
| `isPersisted` | `bool` | `id.isNotEmpty` |

**No photo bytes on `Contact`.**

### Nested types

| Type | Highlights |
|------|------------|
| `Name` | given / middle / family, prefix/suffix, phonetic*, nickname |
| `Phone` | `number`, `PhoneLabel`, `customLabel?`, `isPrimary` |
| `Email` | `address`, `EmailLabel`, `customLabel?`, `isPrimary` |
| `PostalAddress` | street, city, region, postcode, country, neighborhood, poBox + label |
| `Organization` | company, jobTitle, department, phoneticCompany |
| `Website` | `url`, `WebsiteLabel`, `customLabel?` |
| `SocialProfile` | service, userName, userIdentifier, url, label |
| `RelatedPerson` | name + `RelatedPersonLabel` |
| `ContactEvent` | year?, month, day + `ContactEventLabel` |
| `ContactGroup` | id, name, memberCount? |
| `ContactChangeEvent` | `ContactChangeType`, contactId?, timestamp |
| `AvatarSize` | `thumbnail` · `full` |

**Phone labels:** `mobile`, `home`, `work`, `faxHome`, `faxWork`, `pager`, `other`, `custom`  
**Email / postal labels:** `home`, `work`, `other`, `custom`  
**Website labels:** `homepage`, `home`, `work`, `other`, `custom`  
**Event labels:** `birthday`, `anniversary`, `other`, `custom`  
**Related labels:** parent, mother, father, brother, sister, child, friend, spouse, partner, assistant, manager, other, custom  

**Change types:** `added`, `updated`, `deleted`, `unknown`

---

## Errors

Sealed hierarchy — use pattern matching:

```dart
try {
  await api.deleteContact(id);
} on PermissionDeniedException catch (e) {
  // e.mode
} on ContactNotFoundException catch (e) {
  // e.contactId
} on InvalidContactException catch (e) {
  // bad payload / empty id
} on GroupNotFoundException catch (e) {
  // e.groupId
} on PlatformContactsException catch (e) {
  // e.code, e.details
} on ContactsException catch (e) {
  // any contacts failure
}
```

---

## Testing

```dart
import 'package:flutter_contacts_pro/testing.dart';

final fake = FakeContactsPlatform(
  contacts: [
    Contact(id: '1', displayName: 'Ada', phones: [Phone(number: '111')]),
  ],
  permissionStatus: PermissionStatus.granted,
);

final api = FlutterContactsPro(platform: fake);

expect(await api.getContacts(), isA<ContactPage>());
fake.dispose();
```

`FakeContactsPlatform` supports pagination, search, CRUD, groups, avatars, permission denial, and `onContactsChanged`.

---

## Architecture (Flutter side)

```text
App
 └─ FlutterContactsPro          // public facade
     └─ ContactsPlatform        // injectable interface
         ├─ AndroidContactsPlatform   // JNIGEN (after register())
         ├─ UnimplementedContactsPlatform  // default
         └─ FakeContactsPlatform      // tests
```

Domain models stay Dart-idiomatic. Platform/wire details do not leak into app code.

### Performance rules baked into the API

1. **Paginate** — default page size 50, max 500  
2. **Field masks** — don’t fetch detail fields for list rows  
3. **Avatars on demand** — never in `getContacts` / `search`  
4. **Empty search is empty page**, not an error  

---

## Example app

See [`example/`](example/). On Android it registers the real platform and requests permission; elsewhere it uses `FakeContactsPlatform`.

```bash
cd example && flutter run
```

---

## Regenerating Android JNIGEN bindings

```bash
# Build example once so Gradle classpath resolves
cd example && flutter build apk --debug && cd ..

./tool/generate_android_bindings.sh
# or: dart run jnigen --config jnigen.yaml
```

Config: [`jnigen.yaml`](jnigen.yaml). Output: `lib/src/android/bindings/contacts_android.g.dart` (generated — do not edit).

---

## License

See [LICENSE](LICENSE).
