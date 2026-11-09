import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/Panels/add_reservation_panel.dart';
import 'package:hotel_app/database/guest_repository.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/models/bed_configuration.dart';
import 'package:hotel_app/models/room.dart';
import 'package:sqlite3/sqlite3.dart';

Widget _buildForm({
  required List<Room> rooms,
  ReservationRepository? reservationRepository,
  GuestRepository? guestRepository,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AddReservationPanel(
        checkIn: DateTime(2030, 4, 10),
        checkOut: DateTime(2030, 4, 12),
        numberOfGuests: 3,
        selectedRooms: rooms,
        reservationRepository: reservationRepository,
        guestRepository: guestRepository,
      ),
    ),
  );
}

class _FakeReservationRepository extends ReservationRepository {
  int? guestId;
  int addReservationCalls = 0;

  @override
  void addReservation({
    required Map<Room, BedConfigurations> reservedRooms,
    required String guestName,
    required String guestSurname,
    String? email,
    String? phoneNumber,
    int? guestId,
    required int guestCount,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) {
    this.guestId = guestId;
    addReservationCalls++;
  }
}

Room _room({required int id, required int capacity}) {
  return Room(
    id: id,
    roomNumber: id.toString(),
    capacity: capacity,
    extraBed: false,
  );
}

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
    database.execute('CREATE INDEX idx_guests_email ON guests(email)');
    database.execute('CREATE INDEX idx_guests_phone ON guests(phone_number)');
    guestRepository = GuestRepository(database: database);
  });

  tearDown(() {
    database.close();
  });

  testWidgets('rejects a malformed optional email address', (tester) async {
    await tester.pumpWidget(_buildForm(rooms: [_room(id: 1, capacity: 2)]));

    await tester.enterText(find.byType(TextFormField).at(0), 'Alex');
    await tester.enterText(find.byType(TextFormField).at(1), 'Guest');
    await tester.enterText(find.byType(TextFormField).at(2), 'not-an-email');
    await tester.ensureVisible(find.text('Reserve'));
    await tester.tap(find.text('Reserve'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('requires a bed configuration for every selected room', (
    tester,
  ) async {
    await tester.pumpWidget(_buildForm(rooms: [_room(id: 1, capacity: 2)]));

    await tester.enterText(find.byType(TextFormField).at(0), 'Alex');
    await tester.enterText(find.byType(TextFormField).at(1), 'Guest');
    await tester.ensureVisible(find.text('Reserve'));
    await tester.tap(find.text('Reserve'));
    await tester.pumpAndSettle();

    expect(find.text('Select a configuration.'), findsOneWidget);
  });

  testWidgets(
    'each room only offers configurations supported by its capacity',
    (tester) async {
      await tester.pumpWidget(
        _buildForm(
          rooms: [_room(id: 1, capacity: 2), _room(id: 2, capacity: 4)],
        ),
      );

      final dropdowns = find.byType(DropdownButtonFormField<BedConfigurations>);
      expect(dropdowns, findsNWidgets(2));

      await tester.ensureVisible(dropdowns.at(0));
      await tester.tap(dropdowns.at(0));
      await tester.pumpAndSettle();
      expect(find.text('Single bed'), findsOneWidget);
      expect(find.text('Twin beds'), findsOneWidget);
      expect(find.text('Four single beds'), findsNothing);
      await tester.tap(find.text('Twin beds').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(dropdowns.at(1));
      await tester.tap(dropdowns.at(1));
      await tester.pumpAndSettle();
      expect(find.text('Four single beds'), findsOneWidget);
      expect(find.text('Double bed and two single beds'), findsOneWidget);
      expect(find.text('Single bed'), findsNothing);
    },
  );

  for (final useExistingGuest in [true, false]) {
    testWidgets(
      useExistingGuest
          ? 'reuses a guest after confirmation'
          : 'creates a new guest when the match is rejected',
      (tester) async {
        final guestId = guestRepository.addGuest(
          'Alex',
          'Guest',
          'alex@example.com',
          null,
        );
        final reservationRepository = _FakeReservationRepository();
        await tester.pumpWidget(
          _buildForm(
            rooms: [_room(id: 1, capacity: 2)],
            reservationRepository: reservationRepository,
            guestRepository: guestRepository,
          ),
        );

        await tester.enterText(find.byType(TextFormField).at(0), 'Alex');
        await tester.enterText(find.byType(TextFormField).at(1), 'Guest');
        await tester.enterText(
          find.byType(TextFormField).at(2),
          'alex@example.com',
        );
        final configurationDropdown =
            find.byType(DropdownButtonFormField<BedConfigurations>);
        await tester.ensureVisible(configurationDropdown);
        await tester.tap(configurationDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Single bed').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Reserve'));
        await tester.tap(find.text('Reserve'));
        await tester.pumpAndSettle();

        expect(find.text('Is this the correct guest?'), findsOneWidget);
        await tester.tap(
          find.text(
            useExistingGuest
                ? 'Yes, use this guest'
                : 'No, create a new guest',
          ),
        );
        await tester.pumpAndSettle();

        expect(reservationRepository.addReservationCalls, 1);
        expect(
          reservationRepository.guestId,
          useExistingGuest ? guestId : isNull,
        );
      },
    );
  }
}
