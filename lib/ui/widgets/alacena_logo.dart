import 'package:flutter/material.dart';

import '../theme.dart';

class AlacenaLogo extends StatelessWidget {
  const AlacenaLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E281A), kAlacena, Color(0xFFBE6247)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: kAlacena.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.shelves,
        size: size * 0.54,
        color: Colors.white,
      ),
    );
  }
}