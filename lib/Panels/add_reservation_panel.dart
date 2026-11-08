import 'package:flutter/material.dart';
import 'package:hotel_app/models/room.dart';

class AddReservationPanel extends StatefulWidget {
  

  const AddReservationPanel({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.numberOfGuests,
    required this.selectedRooms,
  });
  
  final DateTime checkIn;
  final DateTime checkOut;
  final int numberOfGuests;
  final List<Room> selectedRooms;

  @override
  State<AddReservationPanel> createState() => _AddReservationPanelState();
}

class _AddReservationPanelState extends State<AddReservationPanel> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
