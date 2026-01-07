# Verses App Family — Project Notes

*Last updated: January 6, 2026*

---

## Overview

A family of contemplative scripture apps, each with its own aesthetic identity matched to its spiritual tradition. One core animation engine, many visual expressions.

---

## To Do List

### Bauhaus Bible — Immediate
- [ ] Upload quotes arsenal

### Bauhaus Bible — Features
- [ ] **Three modes:**
  - Random (current) — done ✓
  - Flashcards — mark/save verses, hide/reveal, spaced repetition?
  - Contemplative reading — sequential, chapter structure, slower pace
- [ ] **Details/context panel** — "+" icon opens scrollable page with commentary, context
- [x] **Attribution** — flip card to reveal source (book/chapter/verse) ✓
- [x] **Onboarding** — 3-page gentle overlay (welcome, navigate, breathe) ✓
- [ ] **Dark mode toggle** — inverted cream/black
- [ ] **Sharing** — Export verse as image (tile composition + quote)
- [ ] **Daily notification** — Optional push notification with day's verse
- [ ] **Favorites** — Save verses, return to them
- [ ] **Widget** — iOS/Android home screen widget
- [ ] **Sound design** — Subtle audio when tiles settle (optional)
- [x] **Long text handling** — Dynamic font sizing + auto line-wrapping + smart composition matching ✓
- [ ] **Accessibility** — Later

### Terminal Gita
- [ ] Structure full Gita text (chapters/verses)
- [ ] Terminal aesthetic (green/amber on black, monospace, scanlines)
- [ ] Same engine, new skin

### Lalita Sahasranamam App
- [ ] TBD — to be designed

### Future Designs
- [ ] De Stijl (primaries + rectangles)
- [ ] Stained Glass (Catholic texts, catechism)
- [ ] Sumi-e (Eastern texts, Tao Te Ching, Zen koans)
- [ ] Night Sky (Psalms, mystics)
- [ ] Letterpress (poetry, Rumi)
- [ ] Brutalist

---

## Design Decisions

### Layout
- Square grid centered on any screen size
- Space above and below for UI elements
- Icons sit outside the square, below it
- Keeps the composition itself clean and sacred

### Icon Styles
- **Bauhaus:** Two small squares (filled = source, outline = more)
- **Other aesthetics:** ※ for source, + for more (or themed variations)

### Long Text Handling
- Font scales down via FittedBox (already implemented)
- Scrollable within clearing for very long text
- Fade gradient at bottom hints there's more
- Reading slowly (two lines at a time) may enhance contemplation

### Onboarding
- First quote lands normally with full animation
- Then arrows appear *outside* the square pointing inward
- Non-intrusive, teaches interactions without interrupting the experience

### Attribution (Source)
- Tap icon → card "flips" to show same tile composition with source text instead of quote
- Tap again → flips back
- Different from "more" which opens a full detail page

---

## App Ideas by Tradition

| Aesthetic | Scripture | Vibe |
|-----------|-----------|------|
| Bauhaus | Bible | Modernist sacred geometry |
| De Stijl | Bible (alt) | Mondrian, primary colors, rectangles |
| Stained Glass | Catholic (catechism, liturgy) | Cathedral, luminous, jewel tones |
| Sumi-e | Tao Te Ching, Zen koans | Brush, breath, ink wash |
| Terminal | Bhagavad Gita | Ancient wisdom as code, subversive |
| Night Sky | Psalms, mystics | Nocturnal, stars, contemplation |
| Letterpress | Rumi, poetry | Tactile, crafted, precious |
| Brutalist | TBD | Raw concrete, industrial reverence |
| Lalita Sahasranamam | 1000 names of the Divine Mother | TBD aesthetic |

---

## Technical Notes

### Stack
- Flutter (compiles to iOS, Android, and web from same codebase)
- Google Fonts (using Jost as open-source Futura alternative)

### Publishing
- iOS: Apple Developer account ($99/year), Xcode, App Store review
- Android: Google Play account ($25 one-time), faster review
- Each aesthetic/scripture pairing = separate app (Option B from planning)

### Project Structure
```
bauhaus-bible-random/
├── lib/
│   ├── main.dart              # Core app, animations, UI
│   └── features/
│       ├── verse.dart         # Verse class (text + source)
│       ├── verses_test.dart   # Test verses for checking lengths
│       ├── verses_data.dart   # Real verses (production)
│       └── onboarding.dart    # Onboarding overlay
├── pubspec.yaml
├── .gitignore
└── README.md
```

### Adding Quotes
Edit `lib/features/verses_data.dart`:
```dart
const List<Verse> allVerses = [
  Verse(
    text: "Be still,\nand know that\nI am God.",
    source: "Psalm 46:10",
  ),
  // Add more verses...
];
```
- Use `\n` for manual line breaks (recommended for poetic control)
- Or let auto-wrap handle it (~20 chars per line)

### Switching Test ↔ Production Verses
In `main.dart` at the top:
```dart
// Toggle between test and real verses:
import 'features/verses_test.dart';   // For testing lengths
// import 'features/verses_data.dart'; // For real app
```
And change `testVerses` to `allVerses` in the state class.

---

## Text Sizing System (Technical)

### How It Works

1. **Verse Size Calculation** (`_getVerseSize`)
   - Counts lines after auto-wrapping
   - Returns size 0-4 (tiny → extra large)

2. **Auto Line-Wrapping** (`_autoWrapText`)
   - If verse has manual `\n` breaks: uses those
   - If no breaks: auto-wraps at ~20 characters per line
   - Splits at word boundaries, never mid-word

3. **Dynamic Font Sizing** (`_getFontSize`)
   | Verse Size | Lines | Font Size |
   |------------|-------|-----------|
   | 0 (tiny)   | 1-2   | 24pt      |
   | 1 (small)  | 3     | 22pt      |
   | 2 (medium) | 4-5   | 20pt      |
   | 3 (large)  | 6-7   | 18pt      |
   | 4 (x-large)| 8+    | 16pt      |

4. **FittedBox Scaling**
   - Wraps the text widget with `FittedBox(fit: BoxFit.scaleDown)`
   - If text STILL doesn't fit at calculated font size, scales down further
   - Never scales UP (font size is the maximum)

5. **Smart Composition Matching** (`_getCompatibleCompositions`)
   - Each composition has a "clearing" (white space for text)
   - Clearing area = width × height in grid units
   - Longer verses only get matched to compositions with bigger clearings:

   | Verse Size | Min Clearing Area |
   |------------|-------------------|
   | Tiny/Small | Any               |
   | Medium     | 8+ grid units     |
   | Large      | 12+ grid units    |
   | X-Large    | 16+ grid units    |

### The Flow
```
User taps → _transitionToNext()
         → _pickNextVerseAndComposition()
            → Pick random verse
            → Calculate verse size (after auto-wrap)
            → Find compositions with big enough clearings
            → Pick random compatible composition
         → Fade out old verse
         → Animate tiles to new composition
         → Fade in new verse (with dynamic font size)
```

### Why This Matters
- Short verses get big fonts and can use any composition
- Long verses get smaller fonts AND bigger clearings
- Result: all verses are readable, no manual tweaking needed

---

## Future Features (Ideas)

- **Sharing** — Screenshot/export verse as image with tile composition
- **Daily notification** — Optional push with day's verse
- **Favorites** — Save and return to loved verses
- **Widget** — Home screen widget showing verse in tile aesthetic
- **Sound design** — Subtle tone when tiles settle
- **Modes** — Random / Flashcard / Contemplative reading

---

## Session Log

### January 6, 2026
- **Attribution feature**: 3D flip animation to reveal verse source
  - Tap ■ source button to flip, tap again to flip back
  - Separate from "next verse" tap (no accidental advances)
- **Onboarding**: 3-page gentle overlay (welcome, navigate, breathe)
  - Accessible via "i" button in bottom-right
- **Smart text sizing system**:
  - Auto line-wrapping for verses without manual breaks
  - Dynamic font sizing (24pt tiny → 16pt extra large)
  - Smart composition matching (long verses get big clearings)
  - FittedBox as final fallback scaling
- **File restructure**:
  - `lib/features/` folder for modular add-ons
  - Separate test vs production verse files
  - Easy toggle between test and real verses
- Fixed ghosting bug during transitions

### January 2, 2026
- Built core Bauhaus Bible app with:
  - Sliding tile animations (chain reaction, grid-based movement)
  - Quote appears in calculated clearing (white space)
  - Opening animation (tiles part like curtains)
  - Timing synced: quote fades in as last tiles settle
  - Jost font (Futura alternative)
- Created project structure, pushed to git
- Brainstormed full family of apps and aesthetics
- Decided on Option B: separate apps per aesthetic/scripture pairing
- Documented UI decisions (icons, onboarding, long text handling)
