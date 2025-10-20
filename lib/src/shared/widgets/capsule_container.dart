import 'package:flutter/material.dart';

class CapsuleContainer extends StatelessWidget {
  const CapsuleContainer({
    super.key,
    required this.label,
    required this.onTap,
    required this.isSelected,
  });

  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white70 : Colors.black54,
          borderRadius: BorderRadius.circular(20)
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
