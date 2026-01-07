import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Attribution icon widget - a small filled square that triggers source reveal
class AttributionIcon extends StatelessWidget {
  final VoidCallback onTap;
  final bool isShowingSource;
  final double opacity;

  const AttributionIcon({
    super.key,
    required this.onTap,
    this.isShowingSource = false,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isShowingSource
                ? const Color(0xFF1A1A1A)
                : const Color(0xFF1A1A1A),
            border: isShowingSource
                ? Border.all(color: const Color(0xFF1A1A1A), width: 2)
                : null,
          ),
        ),
      ),
    );
  }
}

/// Source text widget - displays the attribution (book/chapter/verse)
class SourceText extends StatelessWidget {
  final String source;
  final double opacity;

  const SourceText({
    super.key,
    required this.source,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Text(
        source,
        textAlign: TextAlign.center,
        style: GoogleFonts.jost(
          fontSize: 16,
          height: 1.5,
          color: const Color(0xFF2C2C2C),
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Data class for a verse with its source
class Verse {
  final String text;
  final String source;

  const Verse({
    required this.text,
    required this.source,
  });
}

/// Default verses with attributions
const List<Verse> defaultVerses = [
  Verse(
    text: "Be still,\nand know that\nI am God.",
    source: "Psalm 46:10",
  ),
  Verse(
    text: "The light shines\nin the darkness.",
    source: "John 1:5",
  ),
  Verse(
    text: "For everything\nthere is a season.",
    source: "Ecclesiastes 3:1",
  ),
  Verse(
    text: "Love is patient,\nlove is kind.",
    source: "1 Corinthians 13:4",
  ),
  Verse(
    text: "Ask, and it will\nbe given to you.",
    source: "Matthew 7:7",
  ),
];
