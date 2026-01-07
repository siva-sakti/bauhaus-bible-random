import 'verse.dart';

/// ALL VERSES - add your quotes here
///
/// Format:
///   Verse(
///     anchor: "Short hook text.\nUse \\n for line breaks.",
///     full: "Optional full verse text...",  // For "more" view
///     source: "Book Chapter:Verse",
///     commentary: "Optional context and notes...",  // For "more" view
///   ),

const List<Verse> allVerses = [
  // Psalms
  Verse(
    anchor: "Be still,\nand know that\nI am God.",
    source: "Psalm 46:10",
  ),

  // John
  Verse(
    anchor: "The light shines\nin the darkness.",
    source: "John 1:5",
  ),

  // Ecclesiastes
  Verse(
    anchor: "For everything\nthere is a season.",
    source: "Ecclesiastes 3:1",
  ),

  // 1 Corinthians
  Verse(
    anchor: "Love is patient,\nlove is kind.",
    source: "1 Corinthians 13:4",
  ),

  // Matthew
  Verse(
    anchor: "Ask, and it will\nbe given to you.",
    source: "Matthew 7:7",
  ),

  // Add more verses below...

];
