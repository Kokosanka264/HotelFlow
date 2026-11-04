import 'package:flutter/material.dart';
import 'sideBarPanel.dart';
import 'mainPanel.dart';

class MainFrame extends StatefulWidget {
  const MainFrame({super.key});

  @override
  State<MainFrame> createState() => _MainFrameState();
}

class _MainFrameState extends State<MainFrame> {
  
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          SidebarPanel(),
          Expanded(
            child: MainPanel(),
          ),
        ],
      ),
    );
  
}

}