import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/database/guest_repository.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Database database;
  late GuestRepository repository;

  setUp(() {
    database = sqlite3.openInMemory();
    database.execute('''
      CREATE TABLE guests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        guest_name TEXT NOT NULL,
        guest_surname TEXT NOT NULL,
        email TEXT,
        phone_number TEXT
      )
    ''');
    database.execute('CREATE INDEX idx_guests_email ON guests(email)');
    database.execute('CREATE INDEX idx_guests_phone ON guests(phone_number)');
    repository = GuestRepository(database: database);
  });

  tearDown(() {
    database.close();
  });

  test('finds an existing guest by indexed email', () {
    database.execute(
      '''
      INSERT INTO guests (guest_name, guest_surname, email, phone_number)
      VALUES (?, ?, ?, ?)
      ''',
      ['Alex', 'Guest', 'alex@example.com', null],
    );

    expect(repository.findGuestId(email: 'alex@example.com'), 1);
    expect(repository.findGuestId(email: 'missing@example.com'), isNull);
  });

  test('finds an existing guest by indexed phone number', () {
    database.execute(
      '''
      INSERT INTO guests (guest_name, guest_surname, email, phone_number)
      VALUES (?, ?, ?, ?)
      ''',
      ['Alex', 'Guest', null, '+48123456789'],
    );

    expect(repository.findGuestId(phoneNumber: '+48123456789'), 1);
  });

  test('adds a guest and returns the new guest ID when none matches', () {
    final guestId = repository.addGuest(
      'Alex',
      'Guest',
      'alex@example.com',
      '+48123456789',
    );

    final row = database.select('SELECT * FROM guests WHERE id = ?', [
      guestId,
    ]).single;
    expect(row['guest_name'], 'Alex');
    expect(row['guest_surname'], 'Guest');
    expect(
      repository.findGuestId(
        email: 'alex@example.com',
        phoneNumber: '+48123456789',
      ),
      guestId,
    );
  });
}
