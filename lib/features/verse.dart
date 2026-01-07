import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Data class for a verse with its source and optional extended content
class Verse {
  final String anchor;       // Short text for main view (the "hook")
  final String? full;        // Full verse text (optional, for "more" view)
  final String source;       // Book Chapter:Verse
  final String? commentary;  // Context, notes, reflection (optional)

  const Verse({
    required this.anchor,
    this.full,
    required this.source,
    this.commentary,
  });

  /// Check if this verse has additional content for the "more" view
  bool get hasMore => full != null || commentary != null;
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
