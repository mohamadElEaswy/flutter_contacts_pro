# flutter_contacts_pro — API reference

Companion to [SKILL.md](SKILL.md). Full Flutter-side surface.

## `FlutterContactsPro`

| Method | Returns | Notes |
|--------|---------|-------|
| `getPermissionStatus({mode})` | `PermissionStatus` | Default mode `read` |
| `requestPermission({mode})` | `PermissionStatus` | |
| `openSettings()` | `Future<bool>` | |
| `getContacts({query})` | `ContactPage` | Query normalized (pageSize clamp) |
| `search(query, {options})` | `ContactPage` | Trim; empty → `ContactPage.empty` |
| `getContact(id, {fields})` | `Contact?` | Default fields = `detail` |
| `getAvatar(id, {size})` | `Uint8List?` | Default `thumbnail` |
| `hasAvatar(id)` | `bool` | |
| `createContact(contact)` | `Contact` | |
| `updateContact(contact)` | `Contact` | Requires `id` |
| `deleteContact(id)` | `void` | |
| `deleteContacts(ids)` | `void` | Non-transactional |
| `getGroups()` | `List<ContactGroup>` | |
| `createGroup(name)` | `ContactGroup` | |
| `deleteGroup(id)` | `void` | |
| `addContactsToGroup(groupId, ids)` | `void` | |
| `removeContactsFromGroup(groupId, ids)` | `void` | |
| `onContactsChanged` | `Stream<ContactChangeEvent>` | |
| `clearCache()` | `void` | Reserved |

Constructor: `FlutterContactsPro({ContactsPlatform? platform})`  
Singleton: `FlutterContactsPro.instance`

## Enums

**PermissionMode:** `read`, `readWrite`  
**PermissionStatus:** `granted`, `limited`, `denied`, `permanentlyDenied`, `restricted`, `unknown`  
**ContactSort:** `displayNameAsc`, `displayNameDesc`, `updatedAtDesc`  
**AvatarSize:** `thumbnail`, `full`  
**ContactChangeType:** `added`, `updated`, `deleted`, `unknown`  
**ContactField:** see README presets (`minimal` / `list` / `detail`)

## Exceptions

| Type | Extra fields |
|------|----------------|
| `ContactsException` | `message` (sealed base) |
| `PermissionDeniedException` | `mode?` |
| `ContactNotFoundException` | `contactId` |
| `InvalidContactException` | |
| `GroupNotFoundException` | `groupId` |
| `PlatformContactsException` | `code`, `details?` |

## Query constants

- `kDefaultContactPageSize` = 50  
- `kMaxContactPageSize` = 500  

## Testing export

`FakeContactsPlatform` — in-memory CRUD, pagination, search, permissions, avatars, change stream. Call `dispose()` when done.
