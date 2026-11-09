import 'package:flutter/material.dart';
import 'package:hotel_app/Panels/guests_list_view.dart';
import 'package:hotel_app/database/guest_repository.dart';

class GuestsPanel extends StatelessWidget {
  const GuestsPanel({super.key, this.guestRepository});

  final GuestRepository? guestRepository;

  @override
  Widget build(BuildContext context) {
    final repository = guestRepository ?? GuestRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Goście')),
      body: GuestsListView(guestRepository: repository),
    );
  }
}
