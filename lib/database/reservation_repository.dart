import 'database_helper.dart';
import 'package:hotel_app/models/reservation.dart';
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
      checkInDate.toIso8601String().split('T')[0],
      checkOutDate.toIso8601String().split('T')[0],
    ]);
  }
  List<Reservation> getReservationsForDate(DateTime date) {
    final String formattedDate = date.toIso8601String().split('T')[0];
    final rows = DatabaseHelper.database.select(
      '''
      SELECT * FROM reservations
      WHERE DATE(check_in_date) <= ? AND DATE(check_out_date) > ?
      ''',
      [formattedDate, formattedDate],
    );
    return rows.map((row) => Reservation(
      id: row['id'] as int,
      roomId: row['room_id'] as int,
      guestName: row['guest_name'] as String,
      guestSurname: row['guest_surname'] as String,
      email: row['email'] as String?,
      phoneNumber: row['phone_number'] as String?,
      guestCount: row['guest_count'] as int,
      checkInDate: DateTime.parse(row['check_in_date'] as String),
      checkOutDate: DateTime.parse(row['check_out_date'] as String),
    )).toList();
  }
  List<Reservation> getReservationsPage(int page, int pageSize){
    final offset = page * pageSize;
    final rows = DatabaseHelper.database.select(
      '''
      SELECT * FROM reservations
      WHERE Date(check_out_date) >= Date('now')
      ORDER BY check_in_date ASC, id ASC
      LIMIT ? OFFSET ?
      ''',
      [pageSize, offset],
    );
    return rows.map((row) => Reservation(
      id: row['id'] as int,
      roomId: row['room_id'] as int,
      guestName: row['guest_name'] as String,
      guestSurname: row['guest_surname'] as String,
      email: row['email'] as String?,
      phoneNumber: row['phone_number'] as String?,
      guestCount: row['guest_count'] as int,
      checkInDate: DateTime.parse(row['check_in_date'] as String),
      checkOutDate: DateTime.parse(row['check_out_date'] as String),
    )).toList();
  }
}
