import 'package:flutter/material.dart';
import 'package:hotel_app/Panels/in_this_day_reservations.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/models/reservation.dart';

class CalendarPanel extends StatefulWidget {
  const CalendarPanel({super.key});

  @override
  State<CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<CalendarPanel> {
  final ReservationRepository reservationRepository = ReservationRepository();
  List<Reservation> reservations = [];
  DateTime selectedDate = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalendarz')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CalendarDatePicker(
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 10 * 365)),
              onDateChanged: (date) {
                setState(() {
                  loadReservations(date);
                });
              },
            ),
            Expanded(
              child: Container(
                color: const Color.fromARGB(255, 247, 137, 137),
                child: Center(
                  child: DayReservations(
                    selectedDate: selectedDate,
                    reservations: reservations,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void loadReservations(DateTime date) {
    final results = reservationRepository.getReservationsForDate(date);
    setState(() {
      selectedDate = date;
      reservations = results;
    });
  }
}
