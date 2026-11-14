import 'package:flutter/material.dart';
import 'package:hotel_app/database/calendar_date.dart';

class ReservationGuestStage extends StatelessWidget {
  const ReservationGuestStage({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.checkIn,
    required this.checkOut,
    required this.numberOfGuests,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final DateTime checkIn;
  final DateTime checkOut;
  final int numberOfGuests;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: firstNameController,
          decoration: const InputDecoration(labelText: 'First name'),
          validator: (value) => _requiredText(value, 'First name'),
          textCapitalization: TextCapitalization.words,
        ),
        TextFormField(
          controller: lastNameController,
          decoration: const InputDecoration(labelText: 'Last name'),
          validator: (value) => _requiredText(value, 'Last name'),
          textCapitalization: TextCapitalization.words,
        ),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email address'),
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
        ),
        TextFormField(
          controller: phoneController,
          decoration: const InputDecoration(labelText: 'Phone number'),
          keyboardType: TextInputType.phone,
          validator: _validatePhoneNumber,
        ),
        const SizedBox(height: 24),
        _InfoField(label: 'Check-in date', value: calendarDateText(checkIn)),
        const SizedBox(height: 12),
        _InfoField(label: 'Check-out date', value: calendarDateText(checkOut)),
        const SizedBox(height: 12),
        _InfoField(
          label: 'Total number of guests',
          value: numberOfGuests.toString(),
        ),
      ],
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Text(value),
    );
  }
}
