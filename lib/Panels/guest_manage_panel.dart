import 'package:flutter/material.dart';
import 'package:hotel_app/database/guest_repository.dart';
import 'package:hotel_app/models/guest.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

class GuestManagePanel extends StatefulWidget {
  const GuestManagePanel({
    super.key,
    required this.guest,
    required this.guestRepository,
  });

  final Guest guest;
  final GuestRepository guestRepository;

  @override
  State<GuestManagePanel> createState() => _GuestManagePanelState();
}
class _GuestManagePanelState extends State<GuestManagePanel> {
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;
  late final bool _canDeleteGuest;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.guest.name);
    _surnameController = TextEditingController(text: widget.guest.surname);
    _emailController = TextEditingController(text: widget.guest.email ?? '');
    _phoneController = TextEditingController(
      text: widget.guest.phoneNumber ?? '',
    );
    _canDeleteGuest =
        widget.guestRepository.getReservationsByGuestId(widget.guest.id).isEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  Future<void> _saveGuest() async {
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    if (_required(name, 'Name') != null ||
        _required(surname, 'Surname') != null) {
      setState(() {});
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      final email = _emailController.text.trim().isEmpty
          ? widget.guest.email
          : _emailController.text.trim();
      final phoneNumber = _phoneController.text.trim().isEmpty
          ? widget.guest.phoneNumber
          : _phoneController.text.trim();
      final updated = widget.guestRepository.updateGuest(
        guestId: widget.guest.id,
        name: name,
        surname: surname,
        email: email,
        phoneNumber: phoneNumber,
      );
      if (!mounted) {
        return;
      }
      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie znaleziono gościa.')),
        );
        return;
      }
      Navigator.of(context).pop(
        Guest(
          id: widget.guest.id,
          name: name,
          surname: surname,
          email: email,
          phoneNumber: phoneNumber,
        ),
      );
    } on ArgumentError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message?.toString() ?? 'Invalid guest.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _removeGuest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text(
          'Jesteś pewny, że chcech usunąć tego gościa?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Usuń gościa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final removed = widget.guestRepository.removeGuestFromDb(widget.guest.id);
      if (!mounted) {
        return;
      }
      if (!removed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie znaleziono gościa.')),
        );
        return;
      }
      Navigator.of(context).pop(true);
    } on SqliteException catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nie można usunąć gościa: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Zarządzaj gościem',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                IconButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  tooltip: 'Zamknij',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Zmień dane gościa',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Imię'),
              validator: (value) => _required(value, 'Imię'),
            ),
            TextFormField(
              controller: _surnameController,
              decoration: const InputDecoration(labelText: 'Nazwisko'),
              validator: (value) => _required(value, 'Nazwisko'),
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Adres e-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Numer telefonu'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Tooltip(
                  message: _canDeleteGuest
                      ? 'Usuń gościa'
                      : 'Nie można usunąć gościa z rezerwacjami',
                  child: ElevatedButton(
                    onPressed: _canDeleteGuest ? _removeGuest : null,
                    child: const Text('Usuń gościa'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveGuest,
                  child: const Text('Zapisz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}