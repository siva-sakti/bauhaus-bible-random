import 'verse.dart';

/// TEST VERSES - for checking length limits and rendering
/// Switch to verses_data.dart in main.dart when done testing

const List<Verse> testVerses = [
  // TINY (1 line)
  Verse(
    text: "Be still.",
    source: "TEST: Tiny",
  ),

  // SHORT (2 lines)
  Verse(
    text: "The Lord is\nmy shepherd.",
    source: "TEST: Short",
  ),

  // MEDIUM (3-4 lines) - ideal length
  Verse(
    text: "Be still,\nand know that\nI am God.",
    source: "TEST: Medium",
  ),

  // LONG (5-6 lines)
  Verse(
    text: "Trust in the Lord\nwith all your heart\nand lean not on\nyour own understanding;\nin all your ways\nsubmit to him.",
    source: "TEST: Long",
  ),

  // VERY LONG (no line breaks - will auto-wrap and scale down)
  Verse(
    text: "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.",
    source: "TEST: Very Long (auto-wrap)",
  ),

  // VERY LONG with manual line breaks
  Verse(
    text: "For I know the plans\nI have for you,\ndeclares the Lord,\nplans to prosper you\nand not to harm you,\nplans to give you\nhope and a future.",
    source: "TEST: Very Long (manual breaks)",
  ),

  // EXTRA LONG - stress test
  Verse(
    text: "Though the fig tree does not bud and there are no grapes on the vines, though the olive crop fails and the fields produce no food, though there are no sheep in the pen and no cattle in the stalls, yet I will rejoice in the Lord.",
    source: "TEST: Extra Long",
  ),
];
