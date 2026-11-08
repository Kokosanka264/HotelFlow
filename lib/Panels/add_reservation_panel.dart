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
    final screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: screenSize.width * 0.9,
        height: screenSize.height * 0.9,
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nowa rezerwacja', style: TextStyle(fontSize: 24)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // FORMULARZ
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [const Text('Tutaj będzie formularz rezerwacji')],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
