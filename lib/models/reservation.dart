import 'package:hotel_app/models/room.dart';

class Reservation {
  final int id;
  List<Room> reservedRooms;
  String guestName;
  String guestSurname;
  String? email;
  String? phoneNumber;
  int guestCount;
  DateTime checkInDate;
  DateTime checkOutDate;

  Reservation({
    required this.id,
    required this.reservedRooms,
    required this.guestName,
    required this.guestSurname,
    this.email,
    this.phoneNumber,
    required this.guestCount,
    required this.checkInDate,
    required this.checkOutDate,
  });
  int getId() {
    return id;
  }

  @override
  String toString() {
    final roomNumbers = reservedRooms.map((room) => room.roomNumber).join(', ');
    return 'Reservation for $guestName $guestSurname in room(s) $roomNumbers from ${checkInDate.toIso8601String().split('T')[0]} to ${checkOutDate.toIso8601String().split('T')[0]}';
  }
}
