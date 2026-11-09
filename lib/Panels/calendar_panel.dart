import 'package:flutter/material.dart';
import 'package:hotel_app/Panels/remove_reservation_panel.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/methods/reservation_preview.dart';
import 'package:hotel_app/models/reservation.dart';

class CalendarPanel extends StatefulWidget {
  const CalendarPanel({super.key, this.reservationRepository});

  final ReservationRepository? reservationRepository;

  @override
  State<CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<CalendarPanel> {
  late final ReservationRepository reservationRepository =
      widget.reservationRepository ?? ReservationRepository();
  List<Reservation> reservations = [];
  DateTime selectedDate = DateTime.now();

  ({String label, Color backgroundColor, Color textColor}) _statusFor(
    Reservation reservation,
  ) {
    final checkInDate = formatedDate(reservation.checkInDate);
    final checkOutDate = formatedDate(reservation.checkOutDate);

    if (selectedDate == checkInDate) {
      return (
        label: 'Przyjazd',
        backgroundColor: const Color(0xFFDCEBFA),
        textColor: const Color(0xFF24527A),
      );
    }
    if (selectedDate == checkOutDate) {
      return (
        label: 'Wyjazd',
        backgroundColor: const Color(0xFFFFE6CC),
        textColor: const Color(0xFF9A4D00),
      );
    }
    return (
      label: 'Aktualna',
      backgroundColor: const Color(0xFFDDF3E4),
      textColor: const Color(0xFF23613A),
    );
  }

  @override
  void initState() {
    super.initState();
    selectedDate = formatedDate(DateTime.now());
    reservations = reservationRepository.getReservationsForDate(selectedDate);
  }

  Future<void> _showReservationDetails(Reservation reservation) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Szczegóły rezerwacji #${reservation.id}'),
        content: ReservationPreview(reservation: reservation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Zamknij'),
          ),
          TextButton(
            onPressed: () async {
              final removed = await showDialog<bool>(
                context: dialogContext,
                barrierDismissible: false,
                builder: (_) => RemoveReservationPanel(
                  reservation: reservation,
                  reservationRepository: reservationRepository,
                ),
              );
              if (removed == true && dialogContext.mounted) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Usuń rezerwacje'),
          ),
        ],
      ),
    );

    if (deleted == true && mounted) {
      loadReservations(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalendarz')),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: selectedDate,
            firstDate: formatedDate(DateTime.now()),
            lastDate: formatedDate(
              DateTime.now().add(const Duration(days: 10 * 365)),
            ),
            onDateChanged: loadReservations,
          ),
          Expanded(
            child: reservations.isEmpty
                ? Center(
                    child: Text(
                      'Brak rezerwacji na wybrany dzień.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: reservations.length,
                    itemBuilder: (context, index) {
                      final reservation = reservations[index];
                      final status = _statusFor(reservation);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('Rezerwacja #${reservation.id}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${reservation.guestName} '
                                '${reservation.guestSurname}',
                              ),
                              Text(
                                reservation.email?.trim().isNotEmpty == true
                                    ? reservation.email!
                                    : 'Brak adresu e-mail',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: status.backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status.label,
                              style: TextStyle(
                                color: status.textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => _showReservationDetails(reservation),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void loadReservations(DateTime date) {
    date = formatedDate(date);
    final results = reservationRepository.getReservationsForDate(date);
    if (mounted) {
      setState(() {
        selectedDate = date;
        reservations = results;
      });
    }
  }

  DateTime formatedDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
