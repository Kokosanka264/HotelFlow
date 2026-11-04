import 'package:flutter/material.dart';
class MainPanel extends StatefulWidget{
  const MainPanel({super.key});

  @override
  State<MainPanel> createState() => _MainPanelState();
}
  class _MainPanelState extends State<MainPanel> {
  int selectedIndex = 0;

  final List<String> pages = [
    'Strona główna',
    'Pokoje',
    'Rezerwacje',
    'Kalendarz',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
    );
  }
    
} 