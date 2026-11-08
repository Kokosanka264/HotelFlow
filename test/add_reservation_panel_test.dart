import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/Panels/add_reservation_panel.dart';
import 'package:hotel_app/models/bed_configuration.dart';
import 'package:hotel_app/models/room.dart';

Widget _buildForm({required List<Room> rooms}) {
  return MaterialApp(
    home: Scaffold(
      body: AddReservationPanel(
        checkIn: DateTime(2030, 4, 10),
        checkOut: DateTime(2030, 4, 12),
        numberOfGuests: 3,
        selectedRooms: rooms,
      ),
    ),
  );
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
}
