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
  int numberOfGuests = 3,
  ReservationRepository? reservationRepository,
  GuestRepository? guestRepository,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AddReservationPanel(
        checkIn: DateTime(2030, 4, 10),
        checkOut: DateTime(2030, 4, 12),
        numberOfGuests: numberOfGuests,
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

Future<void> _fillGuestStage(
  WidgetTester tester, {
  String email = '',
  String firstName = 'Alex',
  String lastName = 'Guest',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), firstName);
  await tester.enterText(fields.at(1), lastName);
  if (email.isNotEmpty) {
    await tester.enterText(fields.at(2), email);
  }
}

Future<void> _goToRoomStage(WidgetTester tester) async {
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

Future<void> _selectConfiguration(
  WidgetTester tester,
  BedConfigurations configuration,
) async {
  final dropdown = find.byType(DropdownButtonFormField<BedConfigurations>);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  final label = switch (configuration) {
    BedConfigurations.single => 'Pojedyńcze łóżko',
    BedConfigurations.twin => 'Dwa oddzielne łóżka',
    _ => throw ArgumentError('Test helper only supports one/two beds.'),
  };
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
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

  testWidgets('stage one rejects a malformed optional email address', (
    tester,
  ) async {
    await tester.pumpWidget(_buildForm(rooms: [_room(id: 1, capacity: 2)]));

    await _fillGuestStage(tester, email: 'not-an-email');
    await _goToRoomStage(tester);

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Room configuration'), findsNothing);
  });

  testWidgets('stage two requires a bed configuration for every room', (
    tester,
  ) async {
    await tester.pumpWidget(_buildForm(rooms: [_room(id: 1, capacity: 2)]));

    await _fillGuestStage(tester);
    await _goToRoomStage(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Select a configuration.'), findsOneWidget);
    expect(find.text('New reservation - Room configuration'), findsOneWidget);
  });

  testWidgets('stage two rejects insufficient configured capacity', (
    tester,
  ) async {
    await tester.pumpWidget(_buildForm(rooms: [_room(id: 1, capacity: 2)]));

    await _fillGuestStage(tester);
    await _goToRoomStage(tester);
    await _selectConfiguration(tester, BedConfigurations.single);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(
      find.text('Selected room capacity is too small for the guests.'),
      findsOneWidget,
    );
    expect(find.text('Prices and confirmation'), findsNothing);
  });

  testWidgets('room stage only offers configurations supported by capacity', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildForm(rooms: [_room(id: 1, capacity: 2), _room(id: 2, capacity: 4)]),
    );

    await _fillGuestStage(tester);
    await _goToRoomStage(tester);

    final dropdowns = find.byType(DropdownButtonFormField<BedConfigurations>);
    expect(dropdowns, findsNWidgets(2));
    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    expect(find.text('Pojedyńcze łóżko'), findsOneWidget);
    expect(find.text('Dwa oddzielne łóżka'), findsOneWidget);
    expect(find.text('Cztery pojedyńcze łóżka'), findsNothing);
    await tester.tap(find.text('Dwa oddzielne łóżka').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    expect(find.text('Cztery pojedyńcze łóżka'), findsOneWidget);
    expect(find.text('Podwójne łóżko i dwa pojedyńcze'), findsOneWidget);
    expect(find.text('Pojedyńcze łóżko'), findsNothing);
  });

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
            numberOfGuests: 1,
            reservationRepository: reservationRepository,
            guestRepository: guestRepository,
          ),
        );

        await _fillGuestStage(tester, email: 'alex@example.com');
        await _goToRoomStage(tester);
        await _selectConfiguration(tester, BedConfigurations.single);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
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
          numberOfGuests: 2,
          reservationRepository: reservationRepository,
          guestRepository: guestRepository,
        ),
      );

      await _fillGuestStage(tester);
      await _goToRoomStage(tester);
      await _selectConfiguration(tester, BedConfigurations.twin);
      final extraBedSwitch = find.byType(Switch);
      await tester.ensureVisible(extraBedSwitch);
      if (useExtraBed) {
        await tester.tap(extraBedSwitch);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reserve'));
      await tester.pumpAndSettle();

      expect(reservationRepository.extraBeds[room], useExtraBed);
    });
  }
}
