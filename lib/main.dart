import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'Panels/main_frame.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.initialize();
  DatabaseHelper.createTables();
  DatabaseHelper.seedRooms();
  DatabaseHelper.seedReservations();
  runApp(const HotelFlow());
}
class HotelFlow extends StatelessWidget {
  const HotelFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MainFrame(),
      debugShowCheckedModeBanner: false,
      
    );
  }
}