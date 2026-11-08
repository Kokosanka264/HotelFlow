import 'package:hotel_app/Panels/avaliable_rooms_homepage.dart';
import 'package:hotel_app/models/room.dart';
import 'package:flutter/material.dart';
import 'package:hotel_app/widgets/date_input_field.dart';
import 'package:hotel_app/database/room_repository.dart';
import 'package:hotel_app/Panels/add_reservation_panel.dart';
class HomePagePanel extends StatefulWidget {
  HomePagePanel({super.key});
  final RoomRepository roomRepository = RoomRepository();
  @override
  State<HomePagePanel> createState() => _HomePagePanelState();
}

class _HomePagePanelState extends State<HomePagePanel> {
  final TextEditingController _guestController = TextEditingController(
    text: '0',
  );
  late DateTime selectedDateCheckIn = formatedDate(DateTime.now());
  final List<Room> selectedRooms = [];
  late DateTime selectedDateCheckOut = selectedDateCheckIn.add(
    const Duration(days: 1),
  );
  bool isCheckInDateValid = true;
  bool isCheckOutDateValid = true;
  int numberOfGuests = 0;
  int sumOfSpots = 0;
  List<Room> avaliableRooms = [];

  @override
  void dispose() {
    _guestController.dispose();
    super.dispose();
  }

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wyszukaj Pokoje')),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: DateInputField(
                      label: "Data zameldowania",
                      selectedDate: selectedDateCheckIn,
                      firstDate: today,
                      onValidityChanged: (isValid) {
                        isCheckInDateValid = isValid;
                      },
                      onDateChanged: (date) {
                        setState(() {
                          selectedDateCheckIn = date;
                          selectedRooms.clear();
                        });
                      },
                    ),
                  ),

                  Expanded(
                    child: DateInputField(
                      label: "Data wymeldowania",
                      selectedDate: selectedDateCheckOut,
                      firstDate: formatedDate(selectedDateCheckIn)
                          .add(const Duration(days: 1)),
                      onValidityChanged: (isValid) {
                        isCheckOutDateValid = isValid;
                      },
                      onDateChanged: (date) {
                        setState(() {
                          selectedDateCheckOut = date;
                          selectedRooms.clear();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _guestController,
                      decoration: const InputDecoration(
                        labelText: 'Liczba Gości',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          numberOfGuests = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      try {
                        final checkInDate = formatedDate(selectedDateCheckIn);
                        final checkOutDate = formatedDate(selectedDateCheckOut);
                        final todayDate = formatedDate(DateTime.now());

                        if (!isCheckInDateValid ||
                            !isCheckOutDateValid ||
                            checkInDate.isBefore(todayDate) ||
                            numberOfGuests <= 0 ||
                            !checkOutDate.isAfter(checkInDate)) {
                          throw ArgumentError(
                            'Zameldowanie nie może być w przeszłości, a wymeldowanie musi nastąpić później.',
                          );
                        }
                        setState(() {
                          avaliableRooms = widget.roomRepository
                              .getAvaliableRooms(
                                selectedDateCheckIn,
                                selectedDateCheckOut,
                              );
                        });
                      } on ArgumentError catch (e) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Niepoprawne dane'),
                              content: const Text(
                                'Wpisz poprawne daty w formacie YYYY-MM-DD. Zameldowanie nie może być w przeszłości, wymeldowanie musi nastąpić później, a liczba gości musi być większa od zera.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    child: const Text('Szukaj'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AvaliableRoomsView(
                checkIn: selectedDateCheckIn,
                checkOut: selectedDateCheckOut,
                onRoomPressed: toggleSelectedRoom,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: 240,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: numberOfGuests>0 && numberOfGuests<=sumOfSpots ?
                  () {
                     AddReservationPanel( checkIn: selectedDateCheckIn, checkOut: selectedDateCheckOut, numberOfGuests: numberOfGuests, selectedRooms: selectedRooms);
                  }
                  : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj rezerwacje'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime formatedDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void toggleSelectedRoom(Room room) {
    setState(() {
      final index = selectedRooms.indexWhere(
        (selected) => selected.id == room.id,
      );
      int numberOfSpots = room.getCapacity();
      numberOfSpots += room.hasExtra() ? 1:0;
      if (index == -1) {
        selectedRooms.add(room);
        sumOfSpots+=numberOfSpots;
      } else {
        selectedRooms.removeAt(index);
        sumOfSpots -= numberOfSpots;
      }
    });
  }
}
