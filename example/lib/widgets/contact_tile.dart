import 'package:flutter/material.dart';
import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';

import '../utils/contact_formatting.dart';

class ContactTile extends StatelessWidget {
  const ContactTile({super.key, required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = contact.displayName ?? contact.id;
    final subtitle = contactSubtitle(contact);
    final color = avatarColorFor(contact.id, scheme);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        child: Text(
          contactInitials(contact),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: contact.isFavorite
          ? Icon(
              Icons.star_rounded,
              color: scheme.tertiary,
              size: 20,
            )
          : null,
    );
  }
}
