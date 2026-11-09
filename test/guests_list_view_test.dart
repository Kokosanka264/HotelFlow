import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/Panels/guests_panel.dart';
import 'package:hotel_app/database/guest_repository.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Database database;
  late GuestRepository guestRepository;

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
    guestRepository = GuestRepository(database: database);
  });

  tearDown(() {
    database.close();
  });

  testWidgets('shows an empty state when there are no guests', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: GuestsPanel(guestRepository: guestRepository)),
    );

    expect(find.text('Nie znaleziono gości.'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('lists guests and opens their details dialog', (tester) async {
    final guestId = guestRepository.addGuest(
      'Alex',
      'Guest',
      null,
      '123456789',
    );
    guestRepository.addGuest('Bea', 'Example', 'bea@example.com', null);

    await tester.pumpWidget(
      MaterialApp(home: GuestsPanel(guestRepository: guestRepository)),
    );

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(2));
    expect(find.text('Alex Guest'), findsOneWidget);
    expect(find.text('Bea Example'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Alex Guest'));
    await tester.pumpAndSettle();

    expect(find.text('ID gościa: $guestId'), findsOneWidget);
    expect(find.text('Imię: Alex'), findsOneWidget);
    expect(find.text('Nazwisko: Guest'), findsOneWidget);
    expect(find.text('Adres e-mail: Nie podano'), findsOneWidget);
    expect(find.text('Numer telefonu: 123456789'), findsOneWidget);
    expect(find.text('Zamknij'), findsOneWidget);

    await tester.tap(find.text('Zamknij'));
    await tester.pumpAndSettle();

    expect(find.text('ID gościa: $guestId'), findsNothing);
  });

  testWidgets('filters the guest list as the search text changes', (
    tester,
  ) async {
    guestRepository.addGuest('Alex', 'Guest', 'alex@example.com', null);
    guestRepository.addGuest('Bea', 'Example', 'bea@example.com', null);

    await tester.pumpWidget(
      MaterialApp(home: GuestsPanel(guestRepository: guestRepository)),
    );

    await tester.enterText(find.byType(TextField), 'bea');
    await tester.pumpAndSettle();

    expect(find.text('Bea Example'), findsOneWidget);
    expect(find.text('Alex Guest'), findsNothing);
  });
}
