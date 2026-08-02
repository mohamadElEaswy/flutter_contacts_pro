import 'package:flutter_contacts_pro/flutter_contacts_pro.dart';

/// Sample contacts used when running on platforms without a real backend.
final List<Contact> demoContacts = [
  const Contact(
    id: '1',
    displayName: 'Ada Lovelace',
    phones: [Phone(number: '+1 555 0100', label: PhoneLabel.mobile)],
    emails: [Email(address: 'ada@analytical.engine')],
  ),
  const Contact(
    id: '2',
    displayName: 'Grace Hopper',
    emails: [Email(address: 'grace@example.com')],
    phones: [Phone(number: '+1 555 0142', label: PhoneLabel.work)],
  ),
  const Contact(
    id: '3',
    displayName: 'Katherine Johnson',
    phones: [Phone(number: '+1 555 0199', label: PhoneLabel.mobile)],
  ),
  const Contact(
    id: '4',
    displayName: 'Margaret Hamilton',
    emails: [Email(address: 'margaret@apollo.dev')],
  ),
  ..._generatedDemoContacts(),
];

List<Contact> _generatedDemoContacts() {
  const firstNames = [
    'Alan',
    'Barbara',
    'Charles',
    'Diana',
    'Edsger',
    'Frances',
    'Guido',
    'Hedy',
    'Ivan',
    'Jean',
    'Ken',
    'Linus',
    'Marie',
    'Nikola',
    'Olivia',
    'Paula',
    'Quinn',
    'Radia',
    'Steve',
    'Tim',
    'Ursula',
    'Vint',
    'Wendy',
    'Xavier',
    'Yvonne',
    'Zoe',
  ];
  const lastNames = [
    'Turing',
    'Liskov',
    'Babbage',
    'Nyad',
    'Dijkstra',
    'Allen',
    'van Rossum',
    'Lamarr',
    'Sutherland',
    'Sammet',
    'Thompson',
    'Torvalds',
    'Curie',
    'Tesla',
    'Taylor',
    'Perlman',
    'Murphy',
    'Perlman',
    'Wozniak',
    'Berners-Lee',
    'Franklin',
    'Cerf',
    'Hall',
    'Young',
    'Clarke',
    'Mitchell',
  ];

  return [
    for (var i = 0; i < firstNames.length; i++)
      Contact(
        id: '${i + 5}',
        displayName: '${firstNames[i]} ${lastNames[i]}',
        phones: [
          Phone(
            number: '+1 555 ${1000 + i}',
            label: i.isEven ? PhoneLabel.mobile : PhoneLabel.work,
          ),
        ],
        emails: [
          Email(
            address:
                '${firstNames[i].toLowerCase()}.${lastNames[i].toLowerCase().replaceAll(' ', '')}@example.com',
          ),
        ],
        isFavorite: i % 7 == 0,
      ),
  ];
}
