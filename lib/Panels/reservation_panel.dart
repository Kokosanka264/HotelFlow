import 'package:flutter/material.dart';
import 'package:hotel_app/Panels/list_view_panel_reservations.dart';
import 'package:hotel_app/Panels/remove_reservation_panel.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/methods/reservation_preview.dart';
import 'package:hotel_app/models/reservation.dart';

class ReservationPanel extends StatefulWidget {
  const ReservationPanel({super.key, this.reservationRepository});

  final ReservationRepository? reservationRepository;

  @override
  State<ReservationPanel> createState() => _ReservationPanelState();
}

class _ReservationPanelState extends State<ReservationPanel> {
  int page = 0;
  final int pageSize = 20;
  int _refreshVersion = 0;
  late final ReservationRepository reservationRepository =
      widget.reservationRepository ?? ReservationRepository();
  late int maxPage;

  int _lastPageIndex(int reservationCount) {
    if (reservationCount <= 0) {
      return 0;
    }
    return (reservationCount - 1) ~/ pageSize;
  }

  @override
  void initState() {
    super.initState();
    maxPage = _lastPageIndex(reservationRepository.countReservations());
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
      final currentPageReservations = reservationRepository.getReservationsPage(
        page,
        pageSize,
      );
      setState(() {
        if (page > 0 && currentPageReservations.isEmpty) {
          page--;
        }
        maxPage = _lastPageIndex(reservationRepository.countReservations());
        _refreshVersion++;
      });
    }
  }

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
                  onPressed: page < maxPage
                      ? () {
                          setState(() {
                            page++;
                          });
                        }
                      : null,
                ),
              ],
            ),
            Expanded(
              child: ListViewPanelReservations(
                page: page,
                pageSize: pageSize,
                refreshVersion: _refreshVersion,
                reservationRepository: reservationRepository,
                onReservationPressed: _showReservationDetails,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
