import 'package:flutter/material.dart';

/// Loud reminder that money on screen is not real (test key or demo mode).
class TestModeBanner extends StatelessWidget {
  const TestModeBanner({super.key, this.label = 'TEST MODE'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB25E09),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$label — payments are simulated',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
