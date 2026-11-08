import 'package:flutter/material.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/models/reservation.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

class RemoveReservationPanel extends StatelessWidget {
  RemoveReservationPanel({
    super.key,
    required this.reservation,
    ReservationRepository? reservationRepository,
  }) : _reservationRepository =
           reservationRepository ?? ReservationRepository();

  final Reservation reservation;
  final ReservationRepository _reservationRepository;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Potwierdzenie usunięcia rezerwacji'),
      content: Text(
        'Czy na pewno chcesz usunąć tę rezerwację $reservation? \n Tej operacji nie mozna cofnąć.',
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: () {
            try {
              final removed = _reservationRepository.removeReservationFromDb(
                reservation,
              );
              if (!removed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ta rezerwacja już nie istenieje'),
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            } on SqliteException catch (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Nie można usunać rezerwacji: $error')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Usuń rezerwacje'),
        ),
      ],
    );
  }
}
