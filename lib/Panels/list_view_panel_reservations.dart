import 'package:flutter/material.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/models/reservation.dart';
class ListViewPanelReservations extends StatefulWidget {
	const ListViewPanelReservations({
		super.key,
		required this.page,
		required this.pageSize,
    required this.onReservationPressed,
	});

	final int page;
	final int pageSize;
  final void Function(Reservation) onReservationPressed;
	@override
	State<ListViewPanelReservations> createState() =>
			_ListViewPanelReservationsState();
 
  
}

class _ListViewPanelReservationsState
		extends State<ListViewPanelReservations> {
	ReservationRepository reservationRepository = ReservationRepository();
  List<Reservation> reservations = [];
  @override
void didUpdateWidget(
  covariant ListViewPanelReservations oldWidget,
) {
  super.didUpdateWidget(oldWidget);

  if (oldWidget.page != widget.page ||
      oldWidget.pageSize != widget.pageSize) {
    reservations = reservationRepository.getReservationsPage(
      widget.page,
      widget.pageSize,
    );
  }
}
  @override
  void initState() {
    
    super.initState();
   
    reservations = reservationRepository.getReservationsPage(widget.page, widget.pageSize);
  }

	@override
	Widget build(BuildContext context) {
		return ListView.builder(
					itemCount: reservations.length,
					itemBuilder: (context, index) {
						final reservation = reservations[index];
						return ListTile(
							title: Text(reservation.toString()),
							onTap: () => widget.onReservationPressed(reservation),
						);
					},
				);
			}
	}
