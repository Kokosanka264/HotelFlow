import 'package:flutter/material.dart';

class HotelFlowSplashScreen extends StatelessWidget {
  const HotelFlowSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F2EE),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hotel_rounded, color: Color(0xFFB88F9D), size: 64),
                SizedBox(width: 16),
                Text(
                  'HotelFlow',
                  style: TextStyle(
                    color: Color(0xFF3F3940),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                color: Color(0xFFB88F9D),
                backgroundColor: Color(0xFFE8E0DF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
