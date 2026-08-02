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
  static const _pageSize = 50;

  FakeContactsPlatform? _fake;
  late final FlutterContactsPro _api;
  late final bool _requestPermissionOnLoad;
  final ScrollController _scrollController = ScrollController();

  ContactsLoadState _state = ContactsLoadState.loading;
  final List<Contact> _contacts = [];
  String? _nextPageToken;
  int? _estimatedTotal;
  bool _loadingMore = false;
  String? _error;
  PermissionStatus? _permissionStatus;

  bool get _hasMore => _nextPageToken != null;

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
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _fake?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _state != ContactsLoadState.ready) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _load(reset: false);
    }
  }

  Future<void> _load({required bool reset}) async {
    if (!reset && (_loadingMore || !_hasMore)) return;

    if (reset) {
      setState(() {
        _state = ContactsLoadState.loading;
        _error = null;
        _contacts.clear();
        _nextPageToken = null;
        _estimatedTotal = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      if (reset && _requestPermissionOnLoad) {
        final status = await _api.requestPermission();
        if (status != PermissionStatus.granted &&
            status != PermissionStatus.limited) {
          if (!mounted) return;
          setState(() {
            _permissionStatus = status;
            _state = ContactsLoadState.permissionDenied;
            _loadingMore = false;
          });
          return;
        }
      }

      final page = await _api.getContacts(
        query: ContactQuery(
          fields: ContactFields.list,
          pageSize: _pageSize,
          pageToken: reset ? null : _nextPageToken,
        ),
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _contacts
            ..clear()
            ..addAll(page.contacts);
        } else {
          _contacts.addAll(page.contacts);
        }
        _nextPageToken = page.nextPageToken;
        _estimatedTotal = page.estimatedTotal ?? _estimatedTotal;
        _state = ContactsLoadState.ready;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _state = reset ? ContactsLoadState.error : ContactsLoadState.ready;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text('Contacts'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: _state == ContactsLoadState.loading
                    ? null
                    : () => _load(reset: true),
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
                  _subtitle,
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

  String get _subtitle {
    final total = _estimatedTotal;
    final loaded = _contacts.length;
    if (total != null) {
      return 'Showing $loaded of ~$total'
          '${_hasMore ? ' · scroll for more' : ''}';
    }
    return 'Loaded $loaded contacts'
        '${_hasMore ? ' · scroll for more' : ''}';
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
              onAction: () => _load(reset: true),
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
            padding: const EdgeInsets.only(bottom: 8),
            sliver: SliverList.separated(
              itemCount: _contacts.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 88),
              itemBuilder: (context, index) {
                return ContactTile(contact: _contacts[index]);
              },
            ),
          ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
            )
          else if (_hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: OutlinedButton(
                  onPressed: () => _load(reset: false),
                  child: const Text('Load more'),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ];
    }
  }
}
