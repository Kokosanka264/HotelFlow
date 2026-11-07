import 'package:flutter/material.dart';
import 'package:hotel_app/models/reservation.dart';
class DayReservations extends StatelessWidget {
  final List<Reservation> reservations;
   final DateTime selectedDate;
 const DayReservations({super.key, required this.reservations, required this.selectedDate});
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservations for ${selectedDate.toLocal()}'),
      ),
      body: ListView.builder(
        
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('${reservations[index].guestName} ${reservations[index].guestSurname}'),
            subtitle: Text('Room ID: ${reservations[index].roomId}, Guests: ${reservations[index].guestCount}'),
          );
        },
      ),
    );
  }
 
}
