import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'Panels/hotel_flow_splash_screen.dart';
import 'Panels/main_frame.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HotelFlow());
}

class HotelFlow extends StatefulWidget {
  const HotelFlow({super.key});

  @override
  State<HotelFlow> createState() => _HotelFlowState();
}

class _HotelFlowState extends State<HotelFlow> {
  late final Future<void> _initialization = _initialize();

  Future<void> _initialize() async {
    await Future.wait([
      DatabaseHelper.initialize(),
      Future<void>.delayed(const Duration(seconds: 5)),
    ]);
    DatabaseHelper.createTables();
    DatabaseHelper.seedRooms();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const HotelFlowSplashScreen();
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text(
                  'Nie udało się uruchomić HotelFlow: ${snapshot.error}',
                ),
              ),
            );
          }
          return const MainFrame();
        },
      ),
    );
  }
}
