class Reservation{
  final int id;
  int roomId;
  String guestName;
  String guestSurname;
  String? email;
  String? phoneNumber;
  int guestCount;
  DateTime checkInDate;
  DateTime checkOutDate;

  Reservation({
    required this.id,
    required this.roomId,
    required this.guestName,
    required this.guestSurname,
    this.email,
    this.phoneNumber,
    required this.guestCount,
    required this.checkInDate,
    required this.checkOutDate,
  });
  int getId(){
    return id;
  }
  @override
  String toString() {
    return 'Reservation for $guestName $guestSurname in room $roomId from ${checkInDate.toIso8601String().split('T')[0]} to ${checkOutDate.toIso8601String().split('T')[0]}';
  }
}