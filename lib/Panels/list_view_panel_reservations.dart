import 'package:flutter/material.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/models/reservation.dart';

class ListViewPanelReservations extends StatefulWidget {
  const ListViewPanelReservations({
    super.key,
    required this.page,
    required this.pageSize,
    required this.onReservationPressed,
    required this.refreshVersion,
    this.reservationRepository,
  });

  final int page;
  final int pageSize;
  final int refreshVersion;
  final void Function(Reservation) onReservationPressed;
  final ReservationRepository? reservationRepository;

  @override
  State<ListViewPanelReservations> createState() =>
      _ListViewPanelReservationsState();
}

class _ListViewPanelReservationsState extends State<ListViewPanelReservations> {
  late final ReservationRepository reservationRepository =
      widget.reservationRepository ?? ReservationRepository();
  List<Reservation> reservations = [];
  String searchQuery = '';

  @override
  void didUpdateWidget(covariant ListViewPanelReservations oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.page != widget.page ||
        oldWidget.pageSize != widget.pageSize ||
        oldWidget.refreshVersion != widget.refreshVersion) {
      reservations = reservationRepository.getReservationsPage(
        widget.page,
        widget.pageSize,
        searchQuery,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    reservations = reservationRepository.getReservationsPage(
      widget.page,
      widget.pageSize,
      searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Wyszukaj rezerwacje',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
                reservations = reservationRepository.getReservationsPage(
                  widget.page,
                  widget.pageSize,
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
                title: Text(reservation.toString()),
                onTap: () => widget.onReservationPressed(reservation),
              );
            },
          ),
        ),
      ],
    );
  }
}
