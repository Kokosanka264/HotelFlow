import 'package:flutter/material.dart';
class RoomsPanel extends StatelessWidget {
  const RoomsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokoje'),
      ),
      body: Center(
        child: Text('Panel pokoi'),
      ),
    );
  }
}