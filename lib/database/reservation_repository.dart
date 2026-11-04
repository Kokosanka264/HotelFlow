import 'database_helper.dart';
class ReservationRepository {
  void addReservation({
    required int roomId,
    required String guestName,
    required String guestSurname,
    String? email,
    String? phoneNumber,
    required int guestCount,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) {
    if (guestName.trim().isEmpty ||
        guestSurname.trim().isEmpty ||
        guestCount <= 0 ||
        checkInDate.isAfter(checkOutDate)) {
      throw ArgumentError('Invalid reservation data.');
    }

    DatabaseHelper.database.execute('''
      INSERT INTO reservations (
        room_id, guest_name, guest_surname, email, phone_number, guest_count, check_in_date, check_out_date
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      roomId,
      guestName,
      guestSurname,
      email,
      phoneNumber,
      guestCount,
      checkInDate.toIso8601String(),
      checkOutDate.toIso8601String(),
    ]);
  }
}