import 'package:flutter/material.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/methods/reservation_preview.dart';
import 'package:hotel_app/models/reservation.dart';

class ReservationHistoryPanel extends StatefulWidget {
  const ReservationHistoryPanel({super.key, this.reservationRepository});

  final ReservationRepository? reservationRepository;

  @override
  State<ReservationHistoryPanel> createState() =>
      _ReservationHistoryPanelState();
}

class _ReservationHistoryPanelState extends State<ReservationHistoryPanel> {
  late final ReservationRepository reservationRepository =
      widget.reservationRepository ?? ReservationRepository();
  List<Reservation> reservations = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    reservations = reservationRepository.getPastReservations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historia rezerwacji')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Wyszukaj rezerwacje',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  reservations = reservationRepository.getPastReservations(
                    searchQuery,
                  );
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final reservation = reservations[index];
                return ListTile(
                  title: Text('Rezerwacja #${reservation.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reservation.guestName} ${reservation.guestSurname}',
                      ),
                      Text(
                        reservation.email?.trim().isNotEmpty == true
                            ? reservation.email!
                            : 'Brak adresu e-mail',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(
                          'Szczegóły rezerwacji #${reservation.id}',
                        ),
                        content: ReservationPreview(
                          reservation: reservation,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Zamknij'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}