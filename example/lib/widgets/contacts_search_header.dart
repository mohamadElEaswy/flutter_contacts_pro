import 'package:flutter/material.dart';

import 'contacts_search_bar.dart';

class ContactsSearchHeader extends StatelessWidget {
  const ContactsSearchHeader({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ContactsSearchHeaderDelegate(
        controller: controller,
        onChanged: onChanged,
        onClear: onClear,
      ),
    );
  }
}

class _ContactsSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ContactsSearchHeaderDelegate({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  static const _extent = 68.0;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: overlapsContent || shrinkOffset > 0 ? 0.5 : 0,
      child: ContactsSearchBar(
        controller: controller,
        onChanged: onChanged,
        onClear: onClear,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ContactsSearchHeaderDelegate oldDelegate) {
    return controller != oldDelegate.controller ||
        onChanged != oldDelegate.onChanged ||
        onClear != oldDelegate.onClear;
  }
}
