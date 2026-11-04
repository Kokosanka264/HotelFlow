import 'package:flutter/material.dart';
import 'package:hotel_app/widgets/sidebar_button.dart';
class SidebarPanel extends StatefulWidget {
  final ValueChanged<int> onPageSelected;
  final int selectedIndex;
  const SidebarPanel({super.key, required this.onPageSelected, required this.selectedIndex});

  @override
  State<SidebarPanel> createState() => _SidebarPanelState();
  
}
class _SidebarPanelState extends State<SidebarPanel> {
  
  List<String> pages = [
    'Strona główna',
    'Pokoje',
    'Rezerwacje',
    'Kalendarz',
  ];

  @override
  Widget build(BuildContext context) {
   final List<IconData> icons = [
    Icons.home_rounded,
    Icons.bed_rounded,
    Icons.book_online_rounded,
    Icons.calendar_month_rounded,
  ];

  return Container(
    width: 250,
    color: const Color(0xFFF5F2EE),

    child: Column(
      children: [

        // HOTELFLOW LOGO
        Padding(
          padding: const EdgeInsets.all(25),
          child: Row(
            children: [
              const Icon(
                Icons.hotel_rounded,
                color: Color(0xFFB88F9D),
                size: 35,
              ),
              const SizedBox(width: 12),
              const Text(
                "HotelFlow",
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3F3940),
                ),
              ),
            ],
          ),
        ),

        const Divider(
          color: Color(0xFFE8E0DF),
        ),

        // MENU TITLE
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "MAIN MENU",
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                color: Color(0xFF95858B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // NAVIGATION BUTTONS
        Expanded(
          child: ListView.builder(
            itemCount: pages.length,
            itemBuilder: (context, index) {
              return SidebarButton(
                text: pages[index],
                icon: icons[index],
                isSelected: widget.selectedIndex == index,
                onPressed: () {
                  widget.onPageSelected(index);
                },
              );
             
            },
          ),
        ),

        // FOOTER
        const Divider(
          color: Color(0xFFE8E0DF),
        ),

        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "HotelFlow v1.0",
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFA99CA0),
            ),
          ),
        ),
      ],
    ),
  );
}
}
