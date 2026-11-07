import 'package:flutter/material.dart';
import 'package:hotel_app/features/colors_in_app.dart';

class SidebarButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;

  const SidebarButton({
    super.key,
    required this.text,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
     return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),

                child: Material(
                  color: isSelected
                      ? const Color(0xFFE7CFD6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),

                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    leading: Icon(
                      icon,
                      color: isSelected
                          ? AppColors.color1
                          : const Color(0xFF7C6C72),
                    ),

                    title: Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.color1
                            : const Color(0xFF5E5559),
                      ),
                    ),

                    onTap: onPressed,
                  ),
                ),
              );
  }
}