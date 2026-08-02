import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';
import 'package:flutter_contacts_pro/testing.dart';

import '../data/demo_contacts.dart';
import '../widgets/contact_tile.dart';
import '../widgets/status_panel.dart';

enum ContactsLoadState { loading, ready, permissionDenied, error }

class ContactsHomePage extends StatefulWidget {
  const ContactsHomePage({super.key, this.api});

  final FlutterContactsPro? api;

  @override
  State<ContactsHomePage> createState() => _ContactsHomePageState();
}

class _ContactsHomePageState extends State<ContactsHomePage> {
  FakeContactsPlatform? _fake;
  late final FlutterContactsPro _api;
  late final bool _requestPermissionOnLoad;

  ContactsLoadState _state = ContactsLoadState.loading;
  List<Contact> _contacts = const [];
  bool _hasMore = false;
  String? _error;
  PermissionStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    if (widget.api != null) {
      _api = widget.api!;
      _requestPermissionOnLoad = false;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      _api = FlutterContactsPro.instance;
      _requestPermissionOnLoad = true;
    } else {
      _fake = FakeContactsPlatform(contacts: demoContacts);
      _api = FlutterContactsPro(platform: _fake);
      _requestPermissionOnLoad = false;
    }
    _load();
  }

  @override
  void dispose() {
    _fake?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _state = ContactsLoadState.loading;
      _error = null;
    });

    try {
      if (_requestPermissionOnLoad) {
        final status = await _api.requestPermission();
        if (status != PermissionStatus.granted &&
            status != PermissionStatus.limited) {
          if (!mounted) return;
          setState(() {
            _permissionStatus = status;
            _state = ContactsLoadState.permissionDenied;
          });
          return;
        }
      }

      final page = await _api.getContacts(
        query: const ContactQuery(fields: ContactFields.list, pageSize: 20),
      );
      if (!mounted) return;
      setState(() {
        _contacts = page.contacts;
        _hasMore = page.hasMore;
        _state = ContactsLoadState.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _state = ContactsLoadState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text('Contacts'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed:
                    _state == ContactsLoadState.loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (_state == ContactsLoadState.ready)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Loaded ${_contacts.length} contacts'
                  '${_hasMore ? ' · more available' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ..._bodySlivers(),
        ],
      ),
    );
  }

  List<Widget> _bodySlivers() {
    switch (_state) {
      case ContactsLoadState.loading:
        return [
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator.adaptive()),
          ),
        ];
      case ContactsLoadState.permissionDenied:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: StatusPanel(
              icon: Icons.lock_outline_rounded,
              title: 'Permission needed',
              message:
                  'Contacts access is ${_permissionStatus ?? PermissionStatus.denied}. '
                  'Grant permission to load your address book.',
              actionLabel: 'Open settings',
              onAction: () => _api.openSettings(),
            ),
          ),
        ];
      case ContactsLoadState.error:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: StatusPanel(
              icon: Icons.error_outline_rounded,
              title: 'Something went wrong',
              message: _error ?? 'Unknown error',
              actionLabel: 'Try again',
              onAction: _load,
            ),
          ),
        ];
      case ContactsLoadState.ready:
        if (_contacts.isEmpty) {
          return [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: StatusPanel(
                icon: Icons.people_outline_rounded,
                title: 'No contacts yet',
                message: 'Your address book is empty, or nothing matched.',
              ),
            ),
          ];
        }
        return [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: SliverList.separated(
              itemCount: _contacts.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 88),
              itemBuilder: (context, index) {
                return ContactTile(contact: _contacts[index]);
              },
            ),
          ),
        ];
    }
  }
}
