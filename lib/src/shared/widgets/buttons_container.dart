import 'package:flutter/material.dart';

class ButtonsContainer extends StatelessWidget {
  const ButtonsContainer({
    super.key,
    required this.child,
    this.topPosition = false,
  });

  final Widget child;
  final bool topPosition;

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.vertical(
          top: topPosition ? Radius.zero : Radius.circular(20),
          bottom: topPosition ? Radius.circular(20) : Radius.zero,
        ),
      ),
      child: child,
    );
  }
}
