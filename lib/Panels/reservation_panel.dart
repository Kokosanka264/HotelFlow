import 'package:flutter/material.dart';
class ReservationPanel extends StatelessWidget {
  const ReservationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rezerwacje'),
      ),
      body: Center(
        child: Text('Panel rezerwacji'),
      ),
    );
  }
}