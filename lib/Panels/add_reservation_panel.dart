import 'package:flutter/material.dart';
import 'package:hotel_app/database/guest_repository.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/models/bed_configuration.dart';
import 'package:hotel_app/models/guest.dart';
import 'package:hotel_app/models/room.dart';
import 'package:hotel_app/widgets/room_configuration_section.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

class AddReservationPanel extends StatefulWidget {
  const AddReservationPanel({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.numberOfGuests,
    required this.selectedRooms,
    this.reservationRepository,
    this.guestRepository,
  });

  final DateTime checkIn;
  final DateTime checkOut;
  final int numberOfGuests;
  final List<Room> selectedRooms;
  final ReservationRepository? reservationRepository;
  final GuestRepository? guestRepository;

  @override
  State<AddReservationPanel> createState() => _AddReservationPanelState();
}

class _AddReservationPanelState extends State<AddReservationPanel> {
  final _formKey = GlobalKey<FormState>();
  final _selectedConfigurations = <int, BedConfigurations>{};
  late final _reservationRepository =
      widget.reservationRepository ?? ReservationRepository();
  late final _guestRepository = widget.guestRepository ?? GuestRepository();
  bool _isSubmitting = false;

  String _dateText(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String? _requiredText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isNotEmpty && !RegExp(r'^[0-9+().\-\s]{6,20}$').hasMatch(phone)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  Future<void> _submitReservation() async {
    if (_isSubmitting) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedConfigurations.length != widget.selectedRooms.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a bed configuration for each room.'),
        ),
      );
      return;
    }

    final reservedRooms = <Room, BedConfigurations>{
      for (final room in widget.selectedRooms)
        room: _selectedConfigurations[room.id]!,
    };

    setState(() {
      _isSubmitting = true;
    });
    try {
      final email = _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim();
      final phoneNumber = _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim();
      final matchingGuest = email == null && phoneNumber == null
          ? null
          : _guestRepository.findGuest(email: email, phoneNumber: phoneNumber);
      final confirmation = matchingGuest == null
          ? null
          : await _confirmGuest(matchingGuest);
      if (!mounted || (matchingGuest != null && confirmation == null)) {
        return;
      }
      final guestId = confirmation == true ? matchingGuest?.id : null;

      _reservationRepository.addReservation(
        reservedRooms: reservedRooms,
        guestName: _firstNameController.text.trim(),
        guestSurname: _lastNameController.text.trim(),
        email: email,
        phoneNumber: phoneNumber,
        guestId: guestId,
        guestCount: widget.numberOfGuests,
        checkInDate: widget.checkIn,
        checkOutDate: widget.checkOut,
      );
      Navigator.of(context).pop(true);
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message?.toString() ?? 'Invalid reservation.'),
        ),
      );
    } on SqliteException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save reservation: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<bool?> _confirmGuest(Guest guest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Znaleziono istniejącego gościa w bazie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Czy to ten sam gość?'),
            const SizedBox(height: 12),
            Text('${guest.name} ${guest.surname}'),
            if (guest.email != null) Text('Email: ${guest.email}'),
            if (guest.phoneNumber != null) Text('Telefon: ${guest.phoneNumber}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Nie, dodaj nowego gościa'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Tak'),
          ),
        ],
      ),
    );
    if (confirmed == null) {
      return null;
    }
    return confirmed;
  }

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nowa rezerwacja', style: TextStyle(fontSize: 24)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'First name',
                              ),
                              validator: (value) =>
                                  _requiredText(value, 'First name'),
                              textCapitalization: TextCapitalization.words,
                            ),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: 'Last name',
                              ),
                              validator: (value) =>
                                  _requiredText(value, 'Last name'),
                              textCapitalization: TextCapitalization.words,
                            ),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone number',
                              ),
                              keyboardType: TextInputType.phone,
                              validator: _validatePhoneNumber,
                            ),
                            const SizedBox(height: 16),
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Check-in date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(_dateText(widget.checkIn)),
                            ),
                            const SizedBox(height: 12),
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Check-out date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(_dateText(widget.checkOut)),
                            ),
                            const SizedBox(height: 12),
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Total number of guests',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(widget.numberOfGuests.toString()),
                            ),
                            const SizedBox(height: 24),
                            RoomConfigurationSection(
                              rooms: widget.selectedRooms,
                              selectedConfigurations: _selectedConfigurations,
                              onConfigurationChanged: (room, configuration) {
                                setState(() {
                                  if (configuration == null) {
                                    _selectedConfigurations.remove(room.id);
                                  } else {
                                    _selectedConfigurations[room.id] =
                                        configuration;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Delete'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : _submitReservation,
                            child: const Text('Reserve'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
