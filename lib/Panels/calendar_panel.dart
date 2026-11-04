import 'package:flutter/material.dart';
class CalendarPanel extends StatefulWidget {
  const CalendarPanel({super.key});

  @override
  State<CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<CalendarPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
      child: Text(
        'Kalendarz',
        style: TextStyle(fontSize: 24),
      ),
    )
    );
  }
}