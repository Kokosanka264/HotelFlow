import 'package:flutter/material.dart';
class Room extends StatelessWidget {
  const Room({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Pokój 202',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}