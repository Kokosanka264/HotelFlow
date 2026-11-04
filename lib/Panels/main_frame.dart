import 'package:flutter/material.dart';
import 'sidebar_panel.dart';
import 'main_panel.dart';

class MainFrame extends StatefulWidget {
  const MainFrame({super.key});

  @override
  State<MainFrame> createState() => _MainFrameState();
}

class _MainFrameState extends State<MainFrame> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarPanel(onPageSelected: changePage, selectedIndex: selectedIndex),
          Expanded(
            child: MainPanel(selectedIndex: selectedIndex),
          ),
        ],
      ),
    );
  
  } 
  void changePage(int index){
    setState(() {
        selectedIndex = index;
      }
    );

  }

}