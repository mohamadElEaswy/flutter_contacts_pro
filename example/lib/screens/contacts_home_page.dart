import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';
import 'package:flutter_contacts_pro/testing.dart';

import '../data/demo_contacts.dart';
import '../widgets/contact_tile.dart';
import '../widgets/contacts_search_header.dart';
import '../widgets/status_panel.dart';

enum ContactsLoadState { loading, ready, permissionDenied, error }

class ContactsHomePage extends StatefulWidget {
  const ContactsHomePage({super.key, this.api});

  final FlutterContactsPro? api;

  @override
  State<ContactsHomePage> createState() => _ContactsHomePageState();
}

class _ContactsHomePageState extends State<ContactsHomePage> {
  static const _pageSize = 30;
  static const _searchDebounce = Duration(milliseconds: 280);

  FakeContactsPlatform? _fake;
  late final FlutterContactsPro _api;
  late final bool _requestPermissionOnLoad;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  ContactsLoadState _state = ContactsLoadState.loading;
  final List<Contact> _contacts = [];
  String? _nextPageToken;
  int? _estimatedTotal;
  bool _loadingMore = false;
  bool _refreshing = false;
  String? _error;
  PermissionStatus? _permissionStatus;
  String _activeQuery = '';
  int _requestGeneration = 0;
  Timer? _searchDebounceTimer;

  bool get _hasMore => _nextPageToken != null;
  bool get _isSearching => _activeQuery.isNotEmpty;

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
    _searchDebounceTimer?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _fake?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore ||
        _loadingMore ||
        _refreshing ||
        _state != ContactsLoadState.ready) {
      return;
    }
    final position = _scrollController.position;
    if (!position.hasPixels || !position.hasContentDimensions) return;
    if (position.extentAfter < 480) {
      _load(reset: false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {}); // refresh clear button
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      final next = value.trim();
      if (next == _activeQuery) return;
      _activeQuery = next;
      _load(reset: true);
    });
  }

  void _clearSearch() {
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    if (_activeQuery.isEmpty) {
      setState(() {});
      return;
    }
    _activeQuery = '';
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (!reset && (_loadingMore || !_hasMore || _refreshing)) return;

    final generation = ++_requestGeneration;
    final keepExisting = reset && _contacts.isNotEmpty;

    if (reset) {
      setState(() {
        _error = null;
        _nextPageToken = null;
        _estimatedTotal = null;
        _loadingMore = false;
        if (keepExisting) {
          _refreshing = true;
        } else {
          _state = ContactsLoadState.loading;
          _refreshing = false;
          _contacts.clear();
        }
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      if (reset && _requestPermissionOnLoad) {
        final status = await _api.requestPermission();
        if (generation != _requestGeneration) return;
        if (status != PermissionStatus.granted &&
            status != PermissionStatus.limited) {
          if (!mounted) return;
          setState(() {
            _permissionStatus = status;
            _state = ContactsLoadState.permissionDenied;
            _loadingMore = false;
            _refreshing = false;
          });
          return;
        }
      }

      final options = ContactQuery(
        fields: ContactFields.list,
        pageSize: _pageSize,
        pageToken: reset ? null : _nextPageToken,
      );

      final page = _isSearching
          ? await _api.search(_activeQuery, options: options)
          : await _api.getContacts(query: options);

      if (!mounted || generation != _requestGeneration) return;

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
        _refreshing = false;
        _error = null;
      });

      // If the first page is short, preload until scrollable or exhausted.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _requestGeneration) return;
        _onScroll();
      });
    } catch (e) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _error = e.toString();
        if (!keepExisting) {
          _state = ContactsLoadState.error;
        }
        _loadingMore = false;
        _refreshing = false;
      });
      if (keepExisting && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not refresh: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator.adaptive(
        onRefresh: () => _load(reset: true),
        edgeOffset: 120,
        child: CustomScrollView(
          controller: _scrollController,
          scrollCacheExtent: const ScrollCacheExtent.pixels(1200),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar.medium(
              pinned: true,
              title: const Text('Contacts'),
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: (_state == ContactsLoadState.loading ||
                          _refreshing)
                      ? null
                      : () => _load(reset: true),
                  icon: const Icon(Icons.refresh_rounded),
                ),
                const SizedBox(width: 4),
              ],
            ),
            ContactsSearchHeader(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
            if (_refreshing)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_state == ContactsLoadState.ready)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    _subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ..._bodySlivers(),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final total = _estimatedTotal;
    final loaded = _contacts.length;
    final scope = _isSearching ? 'matches' : 'contacts';
    if (total != null) {
      return 'Showing $loaded of ~$total $scope'
          '${_hasMore ? ' · scroll for more' : ''}';
    }
    return 'Loaded $loaded $scope'
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
            SliverFillRemaining(
              hasScrollBody: false,
              child: StatusPanel(
                icon: _isSearching
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                title: _isSearching ? 'No matches' : 'No contacts yet',
                message: _isSearching
                    ? 'Nothing matched “$_activeQuery”.'
                    : 'Your address book is empty, or nothing matched.',
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
                final contact = _contacts[index];
                return ContactTile(
                  key: ValueKey(contact.id),
                  contact: contact,
                );
              },
            ),
          ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
                  ),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ];
    }
  }
}
