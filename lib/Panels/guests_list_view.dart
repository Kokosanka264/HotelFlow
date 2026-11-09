import 'package:flutter/material.dart';
import 'package:hotel_app/database/guest_repository.dart';
import 'package:hotel_app/models/guest.dart';

class GuestsListView extends StatefulWidget {
  const GuestsListView({super.key, required this.guestRepository});

  final GuestRepository guestRepository;

  @override
  State<GuestsListView> createState() => _GuestsListViewState();
}

class _GuestsListViewState extends State<GuestsListView> {
  String search = '';
  late List<Guest> _guests = widget.guestRepository.getGuestsBySearch(search);

  String _optionalValue(String? value) {
    return value == null || value.trim().isEmpty ? 'Nie podano' : value;
  }

  void _showGuestDetails(Guest guest) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${guest.name} ${guest.surname}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID gościa: ${guest.id}'),
            Text('Imię: ${guest.name}'),
            Text('Nazwisko: ${guest.surname}'),
            Text('Adres e-mail: ${_optionalValue(guest.email)}'),
            Text('Numer telefonu: ${_optionalValue(guest.phoneNumber)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Wyszukaj klienta',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                search = value;
                _guests = widget.guestRepository.getGuestsBySearch(search);
              });
            },
          ),
        ),
        Expanded(
          child: _guests.isEmpty
              ? const Center(child: Text('Nie znaleziono gości.'))
              : ListView.builder(
                  itemCount: _guests.length,
                  itemBuilder: (context, index) {
                    final guest = _guests[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ElevatedButton(
                        onPressed: () => _showGuestDetails(guest),
                        child: Text('${guest.name} ${guest.surname}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
