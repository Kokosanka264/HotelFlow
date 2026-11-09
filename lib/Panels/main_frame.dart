import 'package:flutter/material.dart';

import 'sidebar_panel.dart';
import 'main_panel.dart';
import 'settings.dart';

class MainFrame extends StatefulWidget {
  const MainFrame({super.key});

  @override
  State<MainFrame> createState() => _MainFrameState();
}

class _MainFrameState extends State<MainFrame> {
  int selectedIndex = 0;
  bool isSettingsOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              SidebarPanel(
                onPageSelected: changePage,
                selectedIndex: isSettingsOpen ? 5 : selectedIndex,
              ),
              Expanded(child: MainPanel(selectedIndex: selectedIndex)),
            ],
          ),
          if (isSettingsOpen) ...[
            const ModalBarrier(color: Color(0x66000000), dismissible: false),
            Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: 0.94,
                heightFactor: 0.94,
                child: SettingsPanel(onClose: closeSettings),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void changePage(int index) {
    if (index == 5) {
      setState(() {
        isSettingsOpen = true;
      });
      return;
    }

    setState(() {
      selectedIndex = index;
      isSettingsOpen = false;
    });
  }

  void closeSettings() {
    setState(() {
      isSettingsOpen = false;
    });
  }
}
