import 'package:sqlite3/sqlite3.dart';

import 'database_helper.dart';
import 'package:hotel_app/models/guest.dart';

class GuestRepository {
  GuestRepository({Database? database})
    : _database = database ?? DatabaseHelper.database;

  final Database _database;

  List<Guest> getGuestsBySearch(String query) {
    final search = '%$query%';
    final rows = _database.select('''
      SELECT id, guest_name, guest_surname, email, phone_number
      FROM guests
      WHERE guest_name LIKE ?
         OR guest_surname LIKE ?
         OR email LIKE ?
         OR phone_number LIKE ?
      ORDER BY guest_name COLLATE NOCASE, guest_surname COLLATE NOCASE, id
    ''', [search, search, search, search]);
    return rows
        .map(
          (row) => Guest(
            id: row['id'] as int,
            name: row['guest_name'] as String,
            surname: row['guest_surname'] as String,
            email: row['email'] as String?,
            phoneNumber: row['phone_number'] as String?,
          ),
        )
        .toList();
  }

  int? findGuestId({String? email, String? phoneNumber}) {
    return findGuest(email: email, phoneNumber: phoneNumber)?.id;
  }

  Guest? findGuest({String? email, String? phoneNumber}) {
    final normalizedEmail = _normalize(email);
    final normalizedPhoneNumber = _normalize(phoneNumber);
    if (normalizedEmail == null && normalizedPhoneNumber == null) {
      return null;
    }

    final conditions = <String>[];
    final arguments = <Object?>[];
    if (normalizedEmail != null) {
      conditions.add('email = ?');
      arguments.add(normalizedEmail);
    }
    if (normalizedPhoneNumber != null) {
      conditions.add('phone_number = ?');
      arguments.add(normalizedPhoneNumber);
    }

    final rows = _database.select(
      '''
      SELECT id, guest_name, guest_surname, email, phone_number
      FROM guests
      WHERE ${conditions.join(' OR ')}
      LIMIT 2
      ''',
      arguments,
    );

    if (rows.length > 1) {
      throw ArgumentError(
        'Multiple guest records match the supplied email or phone number.',
      );
    }
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.single;
    return Guest(
      id: row['id'] as int,
      name: row['guest_name'] as String,
      surname: row['guest_surname'] as String,
      email: row['email'] as String?,
      phoneNumber: row['phone_number'] as String?,
    );
  }

  int addGuest(
    String name,
    String surname,
    String? email,
    String? phoneNumber,
  ) {
    _database.execute(
      '''
      INSERT INTO guests (guest_name, guest_surname, email, phone_number)
      VALUES (?, ?, ?, ?)
      ''',
      [name.trim(), surname.trim(), _normalize(email), _normalize(phoneNumber)],
    );
    return _database.select('SELECT last_insert_rowid() AS id').first['id']
        as int;
  }

  String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
