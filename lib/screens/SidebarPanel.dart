import 'package:flutter/material.dart';

class SidebarPanel extends StatefulWidget {
  const SidebarPanel({super.key});

  @override
  State<SidebarPanel> createState() => _SidebarPanelState();
  
}
class _SidebarPanelState extends State<SidebarPanel> {
  int selectedIndex = 0;

  List<String> pages = [
    'Strona główna',
    'Pokoje',
    'Rezerwacje',
    'Kalendarz',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.grey[200],
      child: ListView.builder(
        itemCount: pages.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(pages[index]),
            selected: selectedIndex == index,
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
          );
        },
      ),
    );
  }
}
