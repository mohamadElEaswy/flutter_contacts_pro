import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';

/// Sample contacts used when running on platforms without a real backend.
const demoContacts = <Contact>[
  Contact(
    id: '1',
    displayName: 'Ada Lovelace',
    phones: [Phone(number: '+1 555 0100', label: PhoneLabel.mobile)],
    emails: [Email(address: 'ada@analytical.engine')],
  ),
  Contact(
    id: '2',
    displayName: 'Grace Hopper',
    emails: [Email(address: 'grace@example.com')],
    phones: [Phone(number: '+1 555 0142', label: PhoneLabel.work)],
  ),
  Contact(
    id: '3',
    displayName: 'Katherine Johnson',
    phones: [Phone(number: '+1 555 0199', label: PhoneLabel.mobile)],
  ),
  Contact(
    id: '4',
    displayName: 'Margaret Hamilton',
    emails: [Email(address: 'margaret@apollo.dev')],
  ),
];
