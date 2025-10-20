import 'package:flutter/material.dart';

class IconContainer extends StatelessWidget {
  const IconContainer({
    super.key,
    required this.icon,
    this.iconColor = Colors.white70,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Color(0xFF303030),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}
