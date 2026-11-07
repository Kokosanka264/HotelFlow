import 'package:flutter/material.dart';

class DateInputField extends StatefulWidget {
  const DateInputField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.firstDate,
    required this.onDateChanged,
    required this.onValidityChanged,
  });

  final String label;
  final DateTime selectedDate;
  final DateTime firstDate;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<bool> onValidityChanged;

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  late final TextEditingController controller;
  String? errorText;

  String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: formatDate(widget.selectedDate));
  }

  @override
  void didUpdateWidget(covariant DateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedDate != widget.selectedDate) {
      controller.text = formatDate(widget.selectedDate);
      errorText = null;
      widget.onValidityChanged(true);
    }
  }

  DateTime? parseDate(String text) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
      return null;
    }

    final date = DateTime.tryParse(text);

    if (date == null || formatDate(date) != text) {
      return null;
    }

    return date;
  }

  Future<void> openCalendar() async {
    final firstDate = formatedDate(widget.firstDate);
    final lastDate = firstDate.add(const Duration(days: 10 * 365));
    final selectedDate = formatedDate(widget.selectedDate);
    final initialDate = selectedDate.isBefore(firstDate)
        ? firstDate
        : selectedDate.isAfter(lastDate)
        ? lastDate
        : selectedDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null && mounted) {
      controller.text = formatDate(pickedDate);
      setState(() {
        errorText = null;
      });
      widget.onValidityChanged(true);
      widget.onDateChanged(pickedDate);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'YYYY-MM-DD',
        border: const OutlineInputBorder(),
        errorText: errorText,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: openCalendar,
        ),
      ),
      keyboardType: TextInputType.datetime,
      onChanged: (value) {
        final date = parseDate(value);

        setState(() {
          errorText = date == null ? 'Enter a valid date (YYYY-MM-DD)' : null;
        });
        widget.onValidityChanged(date != null);

        if (date != null) {
          widget.onDateChanged(date);
        }
      },
    );
  }

  DateTime formatedDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
