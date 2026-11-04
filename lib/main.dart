import 'package:flutter/material.dart';
import 'database/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.initialize();
  DatabaseHelper.createTables();
  runApp(const HotelFlow());
}
class HotelFlow extends StatelessWidget {
  const HotelFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('My First App'),
        ),
        body: const Center(
          child: Text('MY First App'),
        ),
      ),
    );
  }
}