import 'package:flutter/material.dart';
import 'package:hotel_app/models/room.dart';
class RoomButton extends StatelessWidget {
	const RoomButton({
		super.key,
		required this.room
	});

	final Room room;

	@override
	Widget build(BuildContext context) {
		return ElevatedButton(
			onPressed: () {
				showDialog<void>(
					context: context,
					builder: (dialogContext) => AlertDialog(
						title: Text(room.toString()),
						content: Text('Capacity: ${room.capacity}\nExtra Bed: ${room.extraBed ? 'Yes' : 'No'}'),
						actions: [
							TextButton(
								onPressed: () => Navigator.of(dialogContext).pop(),
								child: const Text('Close'),
							),
						],
					),
				);
			},
			child: Text(room.toString()),
		);
	}
}
