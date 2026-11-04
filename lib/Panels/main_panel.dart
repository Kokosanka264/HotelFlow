import 'package:flutter/material.dart';
import 'home_page_panel.dart';
import 'calendar_panel.dart';
import 'reservation_panel.dart';
import 'rooms_panel.dart';
class MainPanel extends StatelessWidget{
  final int selectedIndex;
  const MainPanel({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getCurrentPage()
    );
  }

  Widget getCurrentPage() {
    switch (selectedIndex) {
      case 0:
        return HomePagePanel();
      case 1:
        return RoomsPanel();
      case 2:
        return ReservationPanel();
      case 3:
        return CalendarPanel();
      default:
        return Center(child: Text('Nieznana strona'));
    }
  }
}
  
  
    
