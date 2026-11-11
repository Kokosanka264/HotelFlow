import 'package:flutter/material.dart';
import 'package:hotel_app/Panels/guest_manage_panel.dart';
import 'package:hotel_app/database/guest_repository.dart';
import 'package:hotel_app/methods/reservation_preview.dart';
import 'package:hotel_app/models/guest.dart';
import 'package:hotel_app/models/reservation.dart';

class GuestReservationsPanel extends StatefulWidget {
  const GuestReservationsPanel({
    super.key,
    required this.guest,
    required this.guestRepository,
  });

  final Guest guest;
  final GuestRepository guestRepository;

  @override
  State<GuestReservationsPanel> createState() =>
      _GuestReservationsPanelState();
}

class _GuestReservationsPanelState extends State<GuestReservationsPanel> {
  late Guest guest = widget.guest;
  late List<Reservation> reservations =
      widget.guestRepository.getReservationsByGuestId(guest.id);

  String _optionalValue(String? value) {
    return value == null || value.trim().isEmpty ? 'Nie podano' : value;
  }

  void _showReservationDetails(BuildContext context, Reservation reservation) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Szczegóły rezerwacji #${reservation.id}'),
        content: ReservationPreview(reservation: reservation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  Future<void> _openGuestManagement() async {
    final result = await showDialog<Object?>(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 500,
          child: GuestManagePanel(
            guest: guest,
            guestRepository: widget.guestRepository,
          ),
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.of(context).pop();
    } else if (result is Guest && mounted) {
      setState(() {
        guest = result;
        reservations = widget.guestRepository.getReservationsByGuestId(
          guest.id,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${guest.name} ${guest.surname}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Zamknij',
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('ID gościa: ${guest.id}'),
          Text('Imię: ${guest.name}'),
          Text('Nazwisko: ${guest.surname}'),
          Text('Adres e-mail: ${_optionalValue(guest.email)}'),
          Text('Numer telefonu: ${_optionalValue(guest.phoneNumber)}'),
          const SizedBox(height: 24),
          Text(
            'Rezerwacje',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: reservations.isEmpty
                ? const Center(child: Text('Brak rezerwacji.'))
                : ListView.builder(
                    itemCount: reservations.length,
                    itemBuilder: (context, index) {
                      final reservation = reservations[index];
                      return ListTile(
                        title: Text('Rezerwacja #${reservation.id}'),
                        subtitle: Text(
                          'Wymeldowanie: '
                          '${reservation.checkOutDate.toIso8601String().split('T')[0]}',
                        ),
                        onTap: () =>
                            _showReservationDetails(context, reservation),
                      );
                    },
                  ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _openGuestManagement,
              child: const Text('Zarządzaj gosciem'),
            ),
          ),
        ],
      ),
    );
  }
}