import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/Panels/home_page_panel.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/database/room_repository.dart';
import 'package:hotel_app/models/bed_configuration.dart';
import 'package:hotel_app/models/room.dart';
import 'package:hotel_app/widgets/room_configuration_section.dart';

class _FakeRoomRepository extends RoomRepository {
  _FakeRoomRepository(this.rooms);

  final List<Room> rooms;

  @override
  List<Room> getAvaliableRooms(DateTime checkIn, DateTime checkOut) => rooms;
}

class _FakeReservationRepository extends ReservationRepository {
  int addReservationCalls = 0;

  @override
  void addReservation({
    required Map<Room, BedConfigurations> reservedRooms,
    required String guestName,
    required String guestSurname,
    String? email,
    String? phoneNumber,
    required int guestCount,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) {
    addReservationCalls++;
  }
}

void main() {
  testWidgets(
    'changing guest count clears earlier room selection before the next search',
    (tester) async {
      final rooms = [
        Room(id: 1, roomNumber: '101', capacity: 2, extraBed: false),
        Room(id: 2, roomNumber: '202', capacity: 4, extraBed: false),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: HomePagePanel(roomRepository: _FakeRoomRepository(rooms)),
        ),
      );

      await tester.enterText(find.byType(TextField).at(2), '1');
      await tester.tap(find.text('Szukaj'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Room 101'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), '3');
      await tester.pumpAndSettle();
      expect(find.text('Room 101'), findsNothing);

      await tester.tap(find.text('Szukaj'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Room 202'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Dodaj rezerwacje'));
      await tester.tap(find.text('Dodaj rezerwacje'));
      await tester.pumpAndSettle();

      final configurationSection = find.byType(RoomConfigurationSection);
      expect(
        find.descendant(
          of: configurationSection,
          matching: find.text('Room 202'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: configurationSection,
          matching: find.text('Room 101'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('resets the home page only after a successful reservation', (
    tester,
  ) async {
    final reservationRepository = _FakeReservationRepository();
    final rooms = [
      Room(id: 1, roomNumber: '101', capacity: 2, extraBed: false),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: HomePagePanel(
          roomRepository: _FakeRoomRepository(rooms),
          reservationRepository: reservationRepository,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(2), '1');
    await tester.tap(find.text('Szukaj'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Room 101'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Dodaj rezerwacje'));
    await tester.tap(find.text('Dodaj rezerwacje'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Alex');
    await tester.enterText(find.byType(TextFormField).at(1), 'Guest');
    final bedConfigurationDropdown = find.byType(
      DropdownButtonFormField<BedConfigurations>,
    );
    await tester.ensureVisible(bedConfigurationDropdown);
    await tester.tap(bedConfigurationDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Single bed').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reserve'));
    await tester.pumpAndSettle();

    expect(reservationRepository.addReservationCalls, 1);
    expect(find.text('Dodaj rezerwacje'), findsNothing);
    expect(find.text('Room 101'), findsNothing);
    expect(find.byType(TextField).at(2), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).controller!.text,
      '0',
    );
  });

  testWidgets('does not reset home page when reservation form is canceled', (
    tester,
  ) async {
    final rooms = [
      Room(id: 1, roomNumber: '101', capacity: 2, extraBed: false),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: HomePagePanel(roomRepository: _FakeRoomRepository(rooms)),
      ),
    );

    await tester.enterText(find.byType(TextField).at(2), '1');
    await tester.tap(find.text('Szukaj'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Room 101'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Dodaj rezerwacje'));
    await tester.tap(find.text('Dodaj rezerwacje'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Dodaj rezerwacje'), findsOneWidget);
    expect(find.text('Room 101'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).controller!.text,
      '1',
    );
  });
}
