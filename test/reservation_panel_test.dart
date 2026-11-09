import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/Panels/reservation_panel.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/models/reservation.dart';

class _FakeReservationRepository extends ReservationRepository {
  _FakeReservationRepository(this.reservationCount);

  final int reservationCount;
  final requestedPages = <int>[];
  final requestedQueries = <String>[];

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
    return [];
  }
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
}
