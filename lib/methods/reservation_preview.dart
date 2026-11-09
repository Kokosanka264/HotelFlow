import 'package:flutter/material.dart';
import 'package:hotel_app/models/bed_configuration.dart';
import 'package:hotel_app/models/reservation.dart';

class ReservationPreview extends StatelessWidget {
  const ReservationPreview({super.key, required this.reservation});

  final Reservation reservation;

  String _date(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _valueOrMissing(String? value) {
    return value == null || value.trim().isEmpty ? 'Nie podano' : value;
  }

  String _price(int grosze) => '${(grosze / 100).toStringAsFixed(2)} PLN';

  String _configurationName(BedConfigurations? configuration) {
    return switch (configuration) {
      BedConfigurations.single => 'Pojedyncze łóżko',
      BedConfigurations.twin => 'Dwa oddzielne łóżka',
      BedConfigurations.doubleBed => 'Podwójne łóżko',
      BedConfigurations.fourSingle => 'Cztery pojedyncze łóżka',
      BedConfigurations.doubleAndTwoSingle => 'Podwójne łóżko i dwa pojedyncze',
      null => 'Nie podano',
    };
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Informacje o rezerwacji',
              style: textStyle?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Numer rezerwacji: ${reservation.id}'),
            Text('Imię: ${reservation.guestName}'),
            Text('Nazwisko: ${reservation.guestSurname}'),
            Text('Adres e-mail: ${_valueOrMissing(reservation.email)}'),
            Text('Numer telefonu: ${_valueOrMissing(reservation.phoneNumber)}'),
            Text('Liczba gości: ${reservation.guestCount}'),
            Text('Zameldowanie: ${_date(reservation.checkInDate)}'),
            Text('Wymeldowanie: ${_date(reservation.checkOutDate)}'),
            Text('Suma rezerwacji: ${_price(reservation.totalGrosze)}'),
            const SizedBox(height: 16),
            Text(
              'Zarezerwowane pokoje',
              style: textStyle?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (reservation.reservedRooms.isEmpty)
              const Text('Brak przypisanych pokoi.')
            else
              for (final room in reservation.reservedRooms) ...[
                Text('Pokój ${room.roomNumber}'),
                Text(
                  'Konfiguracja łóżek: '
                  '${_configurationName(reservation.bedConfigurations[room.id])}',
                ),
                Text(
                  'Dodatkowe łóżko: '
                  '${reservation.extraBeds[room.id] == true ? 'Tak' : 'Nie'}',
                ),
                const Divider(height: 20),
              ],
          ],
        ),
      ),
    );
  }
}
