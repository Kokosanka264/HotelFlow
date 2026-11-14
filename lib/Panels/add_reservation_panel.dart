import 'package:flutter/material.dart';
import 'package:hotel_app/database/calendar_date.dart';
import 'package:hotel_app/database/guest_repository.dart';
import 'package:hotel_app/database/pricing_repository.dart';
import 'package:hotel_app/database/reservation_repository.dart';
import 'package:hotel_app/models/bed_configuration.dart';
import 'package:hotel_app/models/guest.dart';
import 'package:hotel_app/models/room.dart';
import 'package:hotel_app/Panels/reservation_guest_stage.dart';
import 'package:hotel_app/Panels/reservation_price_stage.dart';
import 'package:hotel_app/Panels/reservation_room_stage.dart';
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
    this.pricingRepository,
  });

  final DateTime checkIn;
  final DateTime checkOut;
  final int numberOfGuests;
  final List<Room> selectedRooms;
  final ReservationRepository? reservationRepository;
  final GuestRepository? guestRepository;
  final PricingRepository? pricingRepository;

  @override
  State<AddReservationPanel> createState() => _AddReservationPanelState();
}

class _AddReservationPanelState extends State<AddReservationPanel> {
  final _selectedConfigurations = <int, BedConfigurations>{};
  final _selectedExtraBeds = <int, bool>{};
  final _stageFormKeys = List.generate(3, (_) => GlobalKey<FormState>());
  late final _reservationRepository =
      widget.reservationRepository ?? ReservationRepository();
  late final _guestRepository = widget.guestRepository ?? GuestRepository();
  late final _pricingSettings =
      (widget.pricingRepository ?? PricingRepository()).getSettings();
  final _roomRateControllers = <int, TextEditingController>{};
  final _extraBedRateControllers = <int, TextEditingController>{};
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  int _stage = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (final room in widget.selectedRooms) {
      _roomRateControllers[room.id] = TextEditingController(
        text: _plnText(_pricingSettings.roomRateForCapacity(room.capacity)),
      );
      _extraBedRateControllers[room.id] = TextEditingController(
        text: _plnText(_pricingSettings.extraBedGrosze),
      );
    }
  }

  String _plnText(int grosze) => (grosze / 100).toStringAsFixed(2);

  int? _parseGrosze(String value) {
    final amount = double.tryParse(value.trim().replaceAll(',', '.'));
    if (amount == null || amount.isNaN || amount.isInfinite || amount < 0) {
      return null;
    }
    return (amount * 100).round();
  }

  int _numberOfNights() =>
      calendarDate(widget.checkOut)
          .difference(calendarDate(widget.checkIn))
          .inDays;

  int? _calculateTotalGrosze() {
    var nightlyTotal = 0;
    for (final room in widget.selectedRooms) {
      final roomRate = _parseGrosze(_roomRateControllers[room.id]!.text);
      final extraBedRate = _parseGrosze(
        _extraBedRateControllers[room.id]!.text,
      );
      if (roomRate == null || extraBedRate == null) {
        return null;
      }
      nightlyTotal += roomRate;
      if (_selectedExtraBeds[room.id] == true) {
        nightlyTotal += extraBedRate;
      }
    }
    return nightlyTotal * _numberOfNights();
  }

  int _selectedSpots() {
    return widget.selectedRooms.fold(0, (total, room) {
      final configurationSpots = _selectedConfigurations[room.id]?.spots ?? 0;
      final extraBedSpots = _selectedExtraBeds[room.id] == true ? 1 : 0;
      return total + configurationSpots + extraBedSpots;
    });
  }

  bool get _hasEnoughSpots => _selectedSpots() >= widget.numberOfGuests;

  bool _validateCurrentStage() {
    final isValid = _stageFormKeys[_stage].currentState?.validate() ?? false;
    if (!isValid) {
      return false;
    }
    if (_stage == 0 &&
        (widget.numberOfGuests <= 0 ||
            !calendarDate(widget.checkOut)
                .isAfter(calendarDate(widget.checkIn)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guests and dates must be valid before continuing.'),
        ),
      );
      return false;
    }
    if (_stage == 1 && !_hasEnoughSpots) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected room capacity is too small for the guests.'),
        ),
      );
      return false;
    }
    return true;
  }

  void _goNext() {
    if (!_validateCurrentStage()) {
      return;
    }
    setState(() {
      _stage++;
    });
  }

  void _goBack() {
    if (_stage == 0 || _isSubmitting) {
      return;
    }
    setState(() {
      _stage--;
    });
  }

  Future<void> _submitReservation() async {
    if (_isSubmitting || !_validateCurrentStage()) {
      return;
    }

    final reservedRooms = <Room, BedConfigurations>{
      for (final room in widget.selectedRooms)
        room: _selectedConfigurations[room.id]!,
    };
    final extraBeds = <Room, bool>{
      for (final room in widget.selectedRooms)
        room: _selectedExtraBeds[room.id] ?? false,
    };
    final totalGrosze = _calculateTotalGrosze();
    if (totalGrosze == null) {
      return;
    }

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

      _reservationRepository.setNextReservationTotalGrosze(totalGrosze);
      _reservationRepository.addReservation(
        reservedRooms: reservedRooms,
        extraBeds: extraBeds,
        guestName: _firstNameController.text.trim(),
        guestSurname: _lastNameController.text.trim(),
        email: email,
        phoneNumber: phoneNumber,
        guestId: guestId,
        guestCount: widget.numberOfGuests,
        checkInDate: widget.checkIn,
        checkOutDate: widget.checkOut,
      );
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sukces'),
          content: const Text('Rezerwacja została pomyślnie dodana.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ArgumentError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message?.toString() ?? 'Invalid reservation.'),
        ),
      );
    } on SqliteException catch (error) {
      if (!mounted) {
        return;
      }
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
            if (guest.phoneNumber != null)
              Text('Telefon: ${guest.phoneNumber}'),
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
    return confirmed;
  }

  String _stageTitle() {
    return switch (_stage) {
      0 => 'Guest details',
      1 => 'Room configuration',
      _ => 'Prices and confirmation',
    };
  }

  Widget _stageContent() {
    return switch (_stage) {
      0 => ReservationGuestStage(
        firstNameController: _firstNameController,
        lastNameController: _lastNameController,
        emailController: _emailController,
        phoneController: _phoneController,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        numberOfGuests: widget.numberOfGuests,
      ),
      1 => ReservationRoomStage(
        rooms: widget.selectedRooms,
        selectedConfigurations: _selectedConfigurations,
        selectedExtraBeds: _selectedExtraBeds,
        numberOfGuests: widget.numberOfGuests,
        onConfigurationChanged: (room, configuration) {
          setState(() {
            if (configuration == null) {
              _selectedConfigurations.remove(room.id);
            } else {
              _selectedConfigurations[room.id] = configuration;
            }
          });
        },
        onExtraBedChanged: (room, extraBed) {
          setState(() {
            _selectedExtraBeds[room.id] = extraBed;
          });
        },
      ),
      _ => ReservationPriceStage(
        rooms: widget.selectedRooms,
        roomRateControllers: _roomRateControllers,
        extraBedRateControllers: _extraBedRateControllers,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        guestName: _firstNameController.text.trim(),
        guestSurname: _lastNameController.text.trim(),
        numberOfGuests: widget.numberOfGuests,
        parseGrosze: _parseGrosze,
        calculateTotalGrosze: _calculateTotalGrosze,
        onPriceChanged: () => setState(() {}),
      ),
    };
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    for (final controller in _roomRateControllers.values) {
      controller.dispose();
    }
    for (final controller in _extraBedRateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isLastStage = _stage == 2;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: screenSize.width * 0.9,
        height: screenSize.height * 0.9,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'New reservation - ${_stageTitle()}',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (var index = 0; index < 3; index++)
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                        height: 6,
                        color: index <= _stage
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _stageFormKeys[_stage],
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _stageContent(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  if (_stage > 0)
                    TextButton(onPressed: _goBack, child: const Text('Back')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : isLastStage
                        ? _submitReservation
                        : _goNext,
                    child: Text(isLastStage ? 'Reserve' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
