import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/Panels/reservation_panel.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/models/bed_configuration.dart';
import 'package:hotel_app/models/reservation.dart';
import 'package:hotel_app/models/room.dart';

class _FakeReservationRepository extends ReservationRepository {
  _FakeReservationRepository(this.reservationCount);

  final int reservationCount;
  final requestedPages = <int>[];
  final requestedQueries = <String>[];
  List<Reservation> reservations = [];
  int removeReservationCalls = 0;

  @override
  int countReservations() => reservationCount;

  @override
  List<Reservation> getReservationsPage(
    int page,
    int pageSize, [
    String query = '',
  ]) {
    requestedPages.add(page);
    requestedQueries.add(query);
    return reservations;
  }

  @override
  bool removeReservationFromDb(Reservation reservation) {
    removeReservationCalls++;
    return true;
  }
}

Reservation _sampleReservation() {
  final firstRoom = Room(
    id: 11,
    roomNumber: '101',
    capacity: 2,
    extraBed: true,
  );
  final secondRoom = Room(
    id: 12,
    roomNumber: '202',
    capacity: 4,
    extraBed: true,
  );
  return Reservation(
    id: 42,
    reservedRooms: [firstRoom, secondRoom],
    bedConfigurations: {
      firstRoom.id: BedConfigurations.twin,
      secondRoom.id: BedConfigurations.fourSingle,
    },
    extraBeds: {firstRoom.id: true, secondRoom.id: false},
    guestName: 'Anna',
    guestSurname: 'Kowalska',
    email: 'anna@example.com',
    phoneNumber: '+48123456789',
    guestCount: 3,
    checkInDate: DateTime(2030, 4, 10),
    checkOutDate: DateTime(2030, 4, 12),
  );
}

void main() {
  testWidgets('20 reservations do not enable a second page', (tester) async {
    final repository = _FakeReservationRepository(20);
    await tester.pumpWidget(
      MaterialApp(home: ReservationPanel(reservationRepository: repository)),
    );

    final nextPageButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.arrow_forward_ios),
    );
    expect(nextPageButton.onPressed, isNull);
    expect(repository.requestedPages, [0]);
  });

  testWidgets('21 reservations enable the second page', (tester) async {
    final repository = _FakeReservationRepository(21);
    await tester.pumpWidget(
      MaterialApp(home: ReservationPanel(reservationRepository: repository)),
    );

    final nextPageButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.arrow_forward_ios),
    );
    expect(nextPageButton.onPressed, isNotNull);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_forward_ios));
    await tester.pumpAndSettle();

    expect(repository.requestedPages, [0, 1]);
  });

  testWidgets('search text is passed to the reservation repository', (
    tester,
  ) async {
    final repository = _FakeReservationRepository(0);
    await tester.pumpWidget(
      MaterialApp(home: ReservationPanel(reservationRepository: repository)),
    );

    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.pumpAndSettle();

    expect(repository.requestedQueries.last, 'Alex');
  });

  testWidgets('shows reservation summary and detailed preview on selection', (
    tester,
  ) async {
    final reservation = _sampleReservation();
    final repository = _FakeReservationRepository(1)
      ..reservations = [reservation];
    await tester.pumpWidget(
      MaterialApp(home: ReservationPanel(reservationRepository: repository)),
    );

    expect(find.text('Rezerwacja #42'), findsOneWidget);
    expect(find.text('Anna Kowalska'), findsOneWidget);
    expect(find.text('anna@example.com'), findsOneWidget);

    await tester.tap(find.text('Rezerwacja #42'));
    await tester.pumpAndSettle();

    expect(find.text('ID rezerwacji: 42'), findsOneWidget);
    expect(find.text('Imię gościa: Anna'), findsOneWidget);
    expect(find.text('Nazwisko gościa: Kowalska'), findsOneWidget);
    expect(find.text('Adres e-mail: anna@example.com'), findsOneWidget);
    expect(find.text('Numer telefonu: +48123456789'), findsOneWidget);
    expect(find.text('Liczba gości: 3'), findsOneWidget);
    expect(find.text('Zameldowanie: 2030-04-10'), findsOneWidget);
    expect(find.text('Wymeldowanie: 2030-04-12'), findsOneWidget);
    expect(find.text('Pokój 101'), findsOneWidget);
    expect(
      find.text('Konfiguracja łóżek: Dwa oddzielne łóżka'),
      findsOneWidget,
    );
    expect(find.text('Dodatkowe łóżko: Tak'), findsOneWidget);
    expect(find.text('Pokój 202'), findsOneWidget);
    expect(
      find.text('Konfiguracja łóżek: Cztery pojedyncze łóżka'),
      findsOneWidget,
    );
    expect(find.text('Dodatkowe łóżko: Nie'), findsOneWidget);
    expect(find.text('Zamknij'), findsOneWidget);
    expect(find.text('Usuń rezerwacje'), findsOneWidget);
  });

  testWidgets('details preview retains the reservation deletion workflow', (
    tester,
  ) async {
    final repository = _FakeReservationRepository(1)
      ..reservations = [_sampleReservation()];
    await tester.pumpWidget(
      MaterialApp(home: ReservationPanel(reservationRepository: repository)),
    );

    await tester.tap(find.text('Rezerwacja #42'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usuń rezerwacje').first);
    await tester.pumpAndSettle();

    expect(find.text('Potwierdzenie usunięcia rezerwacji'), findsOneWidget);
    await tester.tap(find.text('Usuń rezerwacje').last);
    await tester.pumpAndSettle();

    expect(repository.removeReservationCalls, 1);
    expect(find.text('Potwierdzenie usunięcia rezerwacji'), findsNothing);
    expect(find.text('Szczegóły rezerwacji #42'), findsNothing);
  });
}
