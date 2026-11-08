import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/Panels/reservation_panel.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/models/reservation.dart';

class _FakeReservationRepository extends ReservationRepository {
  _FakeReservationRepository(this.reservationCount);

  final int reservationCount;
  final requestedPages = <int>[];

  @override
  int countReservations() => reservationCount;

  @override
  List<Reservation> getReservationsPage(int page, int pageSize) {
    requestedPages.add(page);
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
}
