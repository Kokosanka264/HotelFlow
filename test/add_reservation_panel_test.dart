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
  Map<Room, bool> extraBeds = const {};
  int addReservationCalls = 0;

  @override
  void addReservation({
    required Map<Room, BedConfigurations> reservedRooms,
    Map<Room, bool> extraBeds = const {},
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
    this.extraBeds = extraBeds;
    addReservationCalls++;
  }
}

Room _room({required int id, required int capacity, bool extraBed = false}) {
  return Room(
    id: id,
    roomNumber: id.toString(),
    capacity: capacity,
    extraBed: extraBed,
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
      expect(find.text('Pojedyńcze łóżko'), findsOneWidget);
      expect(find.text('Dwa oddzielne łóżka'), findsOneWidget);
      expect(find.text('Cztery pojedyńcze łóżka'), findsNothing);
      await tester.tap(find.text('Dwa oddzielne łóżka').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(dropdowns.at(1));
      await tester.tap(dropdowns.at(1));
      await tester.pumpAndSettle();
      expect(find.text('Cztery pojedyńcze łóżka'), findsOneWidget);
      expect(find.text('Podwójne łóżko i dwa pojedyńcze'), findsOneWidget);
      expect(find.text('Pojedyńcze łóżko'), findsNothing);
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
        final configurationDropdown = find.byType(
          DropdownButtonFormField<BedConfigurations>,
        );
        await tester.ensureVisible(configurationDropdown);
        await tester.tap(configurationDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pojedyńcze łóżko').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Reserve'));
        await tester.tap(find.text('Reserve'));
        await tester.pumpAndSettle();

        expect(find.text('Czy to ten sam gość?'), findsOneWidget);
        await tester.tap(
          find.text(useExistingGuest ? 'Tak' : 'Nie, dodaj nowego gościa'),
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

  for (final useExtraBed in [true, false]) {
    testWidgets('passes extra bed selection $useExtraBed to the reservation', (
      tester,
    ) async {
      final room = _room(id: 1, capacity: 2, extraBed: true);
      final reservationRepository = _FakeReservationRepository();
      await tester.pumpWidget(
        _buildForm(
          rooms: [room],
          reservationRepository: reservationRepository,
          guestRepository: guestRepository,
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Alex');
      await tester.enterText(find.byType(TextFormField).at(1), 'Guest');
      final configurationDropdown = find.byType(
        DropdownButtonFormField<BedConfigurations>,
      );
      await tester.ensureVisible(configurationDropdown);
      await tester.tap(configurationDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pojedyńcze łóżko').last);
      await tester.pumpAndSettle();

      final extraBedSwitch = find.byType(Switch);
      await tester.ensureVisible(extraBedSwitch);
      expect(tester.widget<Switch>(extraBedSwitch).value, isFalse);
      if (useExtraBed) {
        await tester.tap(extraBedSwitch);
        await tester.pumpAndSettle();
      }

      await tester.ensureVisible(find.text('Reserve'));
      await tester.tap(find.text('Reserve'));
      await tester.pumpAndSettle();

      expect(reservationRepository.extraBeds[room], useExtraBed);
    });
  }
}
