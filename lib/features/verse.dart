import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Data class for a verse with its source
class Verse {
  final String text;
  final String source;

  const Verse({
    required this.text,
    required this.source,
  });
}

/// Widget to display the source/attribution text
class SourceText extends StatelessWidget {
  final String source;

  const SourceText({
    super.key,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      source,
      textAlign: TextAlign.center,
      style: GoogleFonts.jost(
        fontSize: 16,
        height: 1.5,
        color: const Color(0xFF2C2C2C),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
    );
  }
}
