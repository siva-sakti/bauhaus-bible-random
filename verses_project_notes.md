# Verses App Family — Project Notes

*Last updated: January 2, 2026*

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
- [ ] **Attribution** — flip card to reveal source (book/chapter/verse)
- [ ] **Onboarding** — After first quote lands, arrows outside the square point to icons/interactions. Teaches: tap for next, source button, more button
- [ ] **Dark mode toggle** — inverted cream/black
- [ ] **Sharing** — Export verse as image (tile composition + quote)
- [ ] **Daily notification** — Optional push notification with day's verse
- [ ] **Favorites** — Save verses, return to them
- [ ] **Widget** — iOS/Android home screen widget
- [ ] **Sound design** — Subtle audio when tiles settle (optional)
- [ ] **Long text handling** — Font scaling, scrollable within clearing with fade gradient hint
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
│   └── main.dart
├── pubspec.yaml
├── .gitignore
└── README.md
```

### Adding Quotes
In `main.dart`, find the quotes list (~line 109):
```dart
final List<String> quotes = [
  "Be still,\nand know that\nI am God.",
  "Your quote here.",
  // use \n for line breaks
];
```

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
