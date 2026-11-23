import 'package:flutter/material.dart';
import 'package:hotel_app/database/calendar_date.dart';
import 'package:hotel_app/models/room.dart';

class ReservationPriceStage extends StatelessWidget {
  const ReservationPriceStage({
    super.key,
    required this.rooms,
    required this.roomRateControllers,
    required this.extraBedRateControllers,
    required this.checkIn,
    required this.checkOut,
    required this.guestName,
    required this.guestSurname,
    required this.numberOfGuests,
    required this.parseGrosze,
    required this.calculateTotalGrosze,
    required this.onPriceChanged,
  });

  final List<Room> rooms;
  final Map<int, TextEditingController> roomRateControllers;
  final Map<int, TextEditingController> extraBedRateControllers;
  final DateTime checkIn;
  final DateTime checkOut;
  final String guestName;
  final String guestSurname;
  final int numberOfGuests;
  final int? Function(String value) parseGrosze;
  final int? Function() calculateTotalGrosze;
  final VoidCallback onPriceChanged;

  String _plnText(int grosze) => (grosze / 100).toStringAsFixed(2);

  String? _validatePrice(String? value) {
    if (value == null || parseGrosze(value) == null) {
      return 'Enter a valid non-negative price.';
    }
    return null;
  }

  int _numberOfNights() =>
      calendarDate(checkOut).difference(calendarDate(checkIn)).inDays;

  @override
  Widget build(BuildContext context) {
    final totalGrosze = calculateTotalGrosze();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reservation summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Guest: $guestName $guestSurname'),
                Text(
                  'Stay: ${calendarDateText(checkIn)} - '
                  '${calendarDateText(checkOut)}',
                ),
                Text('Guests: $numberOfGuests'),
                Text('Nights: ${_numberOfNights()}'),
                Text(
                  'Rooms: ${rooms.map((room) => room.roomNumber).join(', ')}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final room in rooms) ...[
          Text(
            'Room ${room.roomNumber}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: roomRateControllers[room.id],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Room price / night',
                    suffixText: 'PLN',
                  ),
                  validator: _validatePrice,
                  onChanged: (_) => onPriceChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: extraBedRateControllers[room.id],
                  enabled: room.extraBed,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Extra bed / night',
                    suffixText: 'PLN',
                  ),
                  validator: room.extraBed ? _validatePrice : null,
                  onChanged: (_) => onPriceChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            totalGrosze == null
                ? 'Total: enter valid prices'
                : 'Total: ${_plnText(totalGrosze)} PLN',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }
}
