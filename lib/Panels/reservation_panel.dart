import 'package:flutter/material.dart';
import 'package:hotel_app/Panels/list_view_panel_reservations.dart';

class ReservationPanel extends StatefulWidget {
  const ReservationPanel({super.key});
  @override
  State<ReservationPanel> createState() => _ReservationPanelState();
}

class _ReservationPanelState extends State<ReservationPanel> {
  int page = 0;
  int pageSize = 20;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rezerwacje')),
      body: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: page > 0
                      ? () {
                          setState(() {
                            page--;
                          });
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    setState(() {
                      page++;
                    });
                  },
                ),
              ],
            ),
            Expanded(
              child: ListViewPanelReservations(
                page: page,
                pageSize: pageSize,
                onReservationPressed: (reservation) {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text('Reservation Details'),
                      content: Text(reservation.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
