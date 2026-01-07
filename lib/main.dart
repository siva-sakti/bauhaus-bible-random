import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/verse.dart';
import 'features/onboarding.dart';

// Toggle between test and real verses:
import 'features/verses_test.dart';   // For testing lengths
// import 'features/verses_data.dart'; // For real app

void main() {
  runApp(const BibleTilesApp());
}

class BibleTilesApp extends StatelessWidget {
  const BibleTilesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAF8F3),
      ),
      home: const TileRevealScreen(),
    );
  }
}

class TileRevealScreen extends StatefulWidget {
  const TileRevealScreen({super.key});

  @override
  State<TileRevealScreen> createState() => _TileRevealScreenState();
}

class _TileRevealScreenState extends State<TileRevealScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _masterController;
  late AnimationController _quoteFadeOutController;
  
  // Quote fade-in is now tied to tile animation, not separate controller
  double _quoteOpacity = 0.0;
  double _quoteStartTime = 0.0; // When quote starts fading in (normalized 0-1)
  double _quoteEndTime = 1.0;   // When quote is fully visible
  
  final math.Random _random = math.Random();
  
  static const int gridSize = 6;
  
  // Compositions defined only by tile positions
  final List<List<List<int>>> compositionTiles = [
    // Heavy top-right corner
    [
      [0, 0], [0, 1], [0, 2], [0, 3], [0, 4], [0, 5],
      [1, 2], [1, 3], [1, 4], [1, 5],
      [2, 3], [2, 4], [2, 5],
      [3, 4], [3, 5],
      [4, 5],
      [5, 5],
    ],
    
    // Heavy right side with step pattern
    [
      [0, 4], [0, 5],
      [1, 3], [1, 4], [1, 5],
      [2, 2], [2, 3], [2, 4], [2, 5],
      [3, 2], [3, 3], [3, 4], [3, 5],
      [4, 1], [4, 2], [4, 3], [4, 4], [4, 5],
      [5, 1], [5, 2], [5, 3], [5, 4], [5, 5],
    ],
    
    // Bottom-heavy
    [
      [2, 0], [2, 5],
      [3, 0], [3, 1], [3, 4], [3, 5],
      [4, 0], [4, 1], [4, 2], [4, 3], [4, 4], [4, 5],
      [5, 0], [5, 1], [5, 2], [5, 3], [5, 4], [5, 5],
    ],
    
    // Frame - thin border
    [
      [0, 0], [0, 1], [0, 2], [0, 3], [0, 4], [0, 5],
      [1, 0], [1, 5],
      [2, 0], [2, 5],
      [3, 0], [3, 5],
      [4, 0], [4, 5],
      [5, 0], [5, 1], [5, 2], [5, 3], [5, 4], [5, 5],
    ],
    
    // Left-heavy diagonal
    [
      [0, 0], [0, 1], [0, 2],
      [1, 0], [1, 1], [1, 2], [1, 3],
      [2, 0], [2, 1], [2, 2], [2, 3],
      [3, 0], [3, 1], [3, 2],
      [4, 0], [4, 1],
      [5, 0], [5, 1],
    ],
    
    // Top-left and bottom-right blocks
    [
      [0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2], [2, 0], [2, 1],
      [4, 4], [4, 5], [5, 3], [5, 4], [5, 5], [3, 5],
    ],
  ];
  
  List<Rect> _clearings = [];
  
  int _currentComposition = 0;
  int _targetComposition = 1;
  bool _showingQuote = false;
  bool _isTransitioning = false;
  bool _newQuoteFadingIn = false; // Track when fading IN the new quote
  
  List<TileState> _tiles = [];
  
  static const int maxTiles = 30;
  
  // Verses loaded from features/verses_test.dart or verses_data.dart
  final List<Verse> verses = testVerses;  // Change to allVerses for real app
  int _currentQuote = 0;
  int _nextQuote = 0;  // Stores upcoming verse during transition

  // Attribution state
  bool _showingSource = false;
  late AnimationController _flipController;

  // Onboarding state
  bool _showingOnboarding = false;
  int _onboardingPage = 0;

  @override
  void initState() {
    super.initState();

    for (var tiles in compositionTiles) {
      _clearings.add(_findLargestClearing(tiles));
    }

    _masterController = AnimationController(
      duration: const Duration(milliseconds: 6000), // Longer, more relaxed
      vsync: this,
    );

    _quoteFadeOutController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _flipController.addListener(() => setState(() {}));
    
    _masterController.addListener(_onAnimationUpdate);
    _masterController.addStatusListener(_onAnimationStatus);
    
    // Initialize with FULL grid (all tiles), then animate to first composition
    _initializeFullGrid();
    
    // Start the opening animation after a brief moment
    Future.delayed(const Duration(milliseconds: 300), () {
      _animateOpeningSequence();
    });
  }
  
  // Start with all tiles covering the screen
  void _initializeFullGrid() {
    _tiles = [];
    int tileIndex = 0;
    
    // Fill entire 6x6 grid
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        _tiles.add(TileState(
          id: tileIndex,
          currentPos: Offset(col.toDouble(), row.toDouble()),
          targetPos: Offset(col.toDouble(), row.toDouble()),
          path: [],
          delay: 0,
          duration: 0.5,
          isVisible: true,
        ));
        tileIndex++;
      }
    }
  }
  
  // Animate from full grid to first composition (curtains parting)
  void _animateOpeningSequence() {
    // Pick random first verse and matching composition
    _currentQuote = _random.nextInt(verses.length);
    final verseSize = _getVerseSize(verses[_currentQuote]);
    final compatible = _getCompatibleCompositions(verseSize);
    _targetComposition = compatible[_random.nextInt(compatible.length)];

    final targetTiles = compositionTiles[_targetComposition];
    
    // Build set of target positions for quick lookup
    Set<String> targetPositions = {};
    for (var tile in targetTiles) {
      targetPositions.add("${tile[0]},${tile[1]}");
    }
    
    // For each current tile, decide: does it stay or go?
    List<TileState> tilesToKeep = [];
    List<TileState> tilesToExit = [];
    
    for (var tile in _tiles) {
      String posKey = "${tile.currentPos.dy.round()},${tile.currentPos.dx.round()}";
      if (targetPositions.contains(posKey)) {
        tilesToKeep.add(tile);
      } else {
        tilesToExit.add(tile);
      }
    }
    
    // Tiles that stay: no movement needed, but give them a small delay
    // so they feel part of the animation
    for (var tile in tilesToKeep) {
      tile.path = [tile.currentPos]; // Stay in place
      tile.delay = _random.nextDouble() * 0.1;
      tile.duration = 0.1;
      tile.isVisible = true;
    }
    
    // Tiles that exit: slide off screen (away from center, like curtains parting)
    for (var tile in tilesToExit) {
      double centerX = (gridSize - 1) / 2.0;
      double centerY = (gridSize - 1) / 2.0;
      
      // Determine exit direction based on position relative to center
      double dx = tile.currentPos.dx - centerX;
      double dy = tile.currentPos.dy - centerY;
      
      Offset exitPos;
      if (dx.abs() > dy.abs()) {
        // Exit horizontally - push further off screen
        exitPos = Offset(
          dx >= 0 ? gridSize.toDouble() + 1 : -2,
          tile.currentPos.dy,
        );
      } else {
        // Exit vertically - push further off screen
        exitPos = Offset(
          tile.currentPos.dx,
          dy >= 0 ? gridSize.toDouble() + 1 : -2,
        );
      }
      
      tile.path = _generateGridPath(tile.currentPos, exitPos, null);
      tile.targetPos = exitPos;
      // Stagger based on distance from center (center tiles move last, edges first)
      double distFromCenter = (dx.abs() + dy.abs()) / (gridSize);
      tile.delay = 0.3 - (distFromCenter * 0.2) + (_random.nextDouble() * 0.1);
      tile.delay = tile.delay.clamp(0.0, 0.5);
      tile.duration = 0.45;
      tile.isVisible = false; // Will be removed after animation
    }
    
    _tiles = [...tilesToKeep, ...tilesToExit];
    
    // Calculate quote timing
    double latestTileEnd = 0;
    for (var tile in _tiles) {
      double tileEnd = tile.delay + tile.duration;
      if (tileEnd > latestTileEnd) latestTileEnd = tileEnd;
    }
    
    _quoteStartTime = latestTileEnd * 0.6;
    _quoteEndTime = latestTileEnd;
    _quoteOpacity = 0.0;
    _newQuoteFadingIn = true;
    _isTransitioning = true;
    
    _masterController.forward(from: 0);
  }
  
  Rect _findLargestClearing(List<List<int>> tiles) {
    List<List<bool>> grid = List.generate(
      gridSize, 
      (_) => List.filled(gridSize, false),
    );
    
    for (var tile in tiles) {
      int row = tile[0];
      int col = tile[1];
      if (row >= 0 && row < gridSize && col >= 0 && col < gridSize) {
        grid[row][col] = true;
      }
    }
    
    Rect bestClearing = Rect.fromLTWH(0, 0, 3, 2);
    double bestScore = 0;
    
    for (int top = 0; top < gridSize; top++) {
      for (int left = 0; left < gridSize; left++) {
        for (int width = 3; width <= gridSize - left; width++) {
          for (int height = 2; height <= gridSize - top; height++) {
            bool isEmpty = true;
            for (int r = top; r < top + height && isEmpty; r++) {
              for (int c = left; c < left + width && isEmpty; c++) {
                if (grid[r][c]) {
                  isEmpty = false;
                }
              }
            }
            
            if (isEmpty) {
              double area = width * height.toDouble();
              double widthBonus = width >= 4 ? 1.5 : 1.0;
              double aspectRatio = width / height;
              double aspectBonus = (aspectRatio >= 1.0 && aspectRatio <= 2.5) ? 1.3 : 1.0;
              double score = area * widthBonus * aspectBonus;
              
              if (score > bestScore) {
                bestScore = score;
                bestClearing = Rect.fromLTWH(
                  left.toDouble(), 
                  top.toDouble(), 
                  width.toDouble(), 
                  height.toDouble(),
                );
              }
            }
          }
        }
      }
    }
    
    return bestClearing;
  }
  
  // Key function: calculate paths with chain reactions
  void _calculateChainReactionPaths(List<List<int>> targetPositions) {
    // Build a map of current positions
    Map<String, int> currentOccupancy = {}; // "row,col" -> tile index
    for (int i = 0; i < _tiles.length; i++) {
      final pos = _tiles[i].currentPos;
      final key = "${pos.dy.round()},${pos.dx.round()}";
      currentOccupancy[key] = i;
    }
    
    // Build a map of target positions
    Map<String, int> targetOccupancy = {}; // "row,col" -> tile index that wants to go there
    Map<int, Offset> tileTargets = {}; // tile index -> target position
    
    for (int i = 0; i < _tiles.length; i++) {
      if (i < targetPositions.length) {
        final target = Offset(
          targetPositions[i][1].toDouble(),
          targetPositions[i][0].toDouble(),
        );
        tileTargets[i] = target;
        final key = "${target.dy.round()},${target.dx.round()}";
        targetOccupancy[key] = i;
        _tiles[i].targetPos = target;
        _tiles[i].isVisible = true;
      } else {
        // Tile needs to exit - push further off screen to avoid edge visibility
        final exitTarget = Offset(
          _random.nextBool() ? -2 : gridSize.toDouble() + 1,
          _tiles[i].currentPos.dy,
        );
        tileTargets[i] = exitTarget;
        _tiles[i].targetPos = exitTarget;
        _tiles[i].isVisible = false;
      }
    }
    
    // Calculate dependency chains
    // A tile depends on another if that other tile is currently sitting on A's target
    Map<int, int> blockedBy = {}; // tile index -> index of tile blocking it
    
    for (int i = 0; i < _tiles.length; i++) {
      final target = tileTargets[i];
      if (target == null) continue;
      
      final targetKey = "${target.dy.round()},${target.dx.round()}";
      
      // Is someone currently at my target?
      if (currentOccupancy.containsKey(targetKey)) {
        int blockerIndex = currentOccupancy[targetKey]!;
        // Make sure it's not myself (tile staying in place)
        if (blockerIndex != i) {
          blockedBy[i] = blockerIndex;
        }
      }
    }
    
    // Calculate chain depths (how many tiles are in front of me in the chain)
    Map<int, int> chainDepth = {};
    
    int getChainDepth(int tileIndex, Set<int> visited) {
      if (chainDepth.containsKey(tileIndex)) {
        return chainDepth[tileIndex]!;
      }
      
      if (visited.contains(tileIndex)) {
        // Cycle detected - break it
        return 0;
      }
      
      visited.add(tileIndex);
      
      if (!blockedBy.containsKey(tileIndex)) {
        // Not blocked by anyone - can move first
        chainDepth[tileIndex] = 0;
        return 0;
      }
      
      int blockerIndex = blockedBy[tileIndex]!;
      int blockerDepth = getChainDepth(blockerIndex, visited);
      chainDepth[tileIndex] = blockerDepth + 1;
      return blockerDepth + 1;
    }
    
    // Calculate depths for all tiles
    int maxDepth = 0;
    for (int i = 0; i < _tiles.length; i++) {
      int depth = getChainDepth(i, {});
      if (depth > maxDepth) maxDepth = depth;
    }
    
    // Assign delays based on chain depth
    // Tiles with depth 0 move first, depth 1 waits for them, etc.
    double delayPerDepth = 0.10; // Each chain level adds this much delay
    double baseMoveDuration = 0.50; // How long each tile takes to move (longer = gentler)
    
    for (int i = 0; i < _tiles.length; i++) {
      int depth = chainDepth[i] ?? 0;
      
      // Add small random variation within each depth level
      double randomVariation = _random.nextDouble() * 0.05;
      
      _tiles[i].delay = depth * delayPerDepth + randomVariation;
      _tiles[i].duration = baseMoveDuration;
      
      // Generate the path
      _tiles[i].path = _generateGridPath(
        _tiles[i].currentPos, 
        _tiles[i].targetPos,
        blockedBy.containsKey(i) ? blockedBy[i] : null,
      );
    }
  }
  
  // Generate grid path, potentially routing around a blocker
  List<Offset> _generateGridPath(Offset start, Offset end, int? blockerIndex) {
    List<Offset> path = [start];
    
    int currentCol = start.dx.round();
    int currentRow = start.dy.round();
    int targetCol = end.dx.round();
    int targetRow = end.dy.round();
    
    // If we have a blocker, we might need to take an indirect path
    // This creates the "pushing" effect - we start moving toward blocker,
    // which forces them to move, then we continue
    
    bool horizontalFirst;
    
    if (blockerIndex != null && _tiles.length > blockerIndex) {
      // Move toward the blocker first (this creates the "pushing" visual)
      Offset blockerPos = _tiles[blockerIndex].currentPos;
      
      // If blocker is more horizontal from us, go horizontal first
      double horizDist = (blockerPos.dx - currentCol).abs();
      double vertDist = (blockerPos.dy - currentRow).abs();
      horizontalFirst = horizDist >= vertDist;
    } else {
      horizontalFirst = _random.nextBool();
    }
    
    if (horizontalFirst) {
      while (currentCol != targetCol) {
        currentCol += (targetCol > currentCol) ? 1 : -1;
        path.add(Offset(currentCol.toDouble(), currentRow.toDouble()));
      }
      while (currentRow != targetRow) {
        currentRow += (targetRow > currentRow) ? 1 : -1;
        path.add(Offset(currentCol.toDouble(), currentRow.toDouble()));
      }
    } else {
      while (currentRow != targetRow) {
        currentRow += (targetRow > currentRow) ? 1 : -1;
        path.add(Offset(currentCol.toDouble(), currentRow.toDouble()));
      }
      while (currentCol != targetCol) {
        currentCol += (targetCol > currentCol) ? 1 : -1;
        path.add(Offset(currentCol.toDouble(), currentRow.toDouble()));
      }
    }
    
    return path;
  }
  
  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _isTransitioning = false;
      _currentComposition = _targetComposition;
      
      _tiles.removeWhere((t) => !t.isVisible || 
          t.currentPos.dx < 0 || t.currentPos.dx >= gridSize ||
          t.currentPos.dy < 0 || t.currentPos.dy >= gridSize);
      
      // Snap tiles to final positions
      for (var tile in _tiles) {
        tile.currentPos = tile.targetPos;
      }
      
      // Ensure quote is fully visible after animation completes
      if (_newQuoteFadingIn) {
        setState(() {
          _quoteOpacity = 1.0;
          _showingQuote = true;
          _newQuoteFadingIn = false;
        });
      }
    }
  }
  
  void _onAnimationUpdate() {
    setState(() {
      final t = _masterController.value;
      
      // Update tile positions
      for (int i = 0; i < _tiles.length; i++) {
        final tile = _tiles[i];
        if (tile.path.isEmpty) continue;
        
        final tileStart = tile.delay;
        final tileEnd = tile.delay + tile.duration;
        
        double localT;
        if (t < tileStart) {
          localT = 0;
        } else if (t > tileEnd) {
          localT = 1;
        } else {
          localT = (t - tileStart) / (tileEnd - tileStart);
        }
        
        // Use easeInOutSine for smooth, gentle motion
        final easedT = Curves.easeInOutSine.transform(localT);
        
        final pathLength = tile.path.length - 1;
        if (pathLength <= 0) {
          tile.currentPos = tile.path.first;
        } else {
          final pathPosition = easedT * pathLength;
          final segmentIndex = pathPosition.floor().clamp(0, pathLength - 1);
          final segmentT = pathPosition - segmentIndex;
          
          final from = tile.path[segmentIndex];
          final to = tile.path[(segmentIndex + 1).clamp(0, pathLength)];
          
          tile.currentPos = Offset.lerp(from, to, segmentT)!;
        }
      }
      
      // Calculate quote opacity - tied directly to tile timing
      // Only update if we're fading IN (not during fade-out)
      if (_newQuoteFadingIn) {
        if (t < _quoteStartTime) {
          _quoteOpacity = 0.0;
        } else if (t >= _quoteEndTime) {
          _quoteOpacity = 1.0;
        } else {
          double quoteT = (t - _quoteStartTime) / (_quoteEndTime - _quoteStartTime);
          // Use easeIn curve - stays faint longer, then solidifies at the end
          // This way quote doesn't feel "readable" until tiles are nearly settled
          _quoteOpacity = Curves.easeInQuart.transform(quoteT);
        }
        
        // Show quote widget once we start fading in
        if (t >= _quoteStartTime && !_showingQuote) {
          _showingQuote = true;
        }
      }
    });
  }
  
  bool _tilesStarted = false; // Track if we've started tile movement
  
  void _transitionToNext() {
    if (_isTransitioning) return;

    // Reset source view if showing
    if (_showingSource) {
      _showingSource = false;
      _flipController.reset();
    }

    setState(() {
      _isTransitioning = true;
      _newQuoteFadingIn = false;
      _tilesStarted = false;
    });

    // Pick next verse and matching composition BEFORE starting fade
    _pickNextVerseAndComposition();

    // Fade out current quote - tiles will start when opacity drops
    _quoteFadeOutController.addListener(_onFadeOutUpdate);
    _quoteFadeOutController.forward(from: 0).then((_) {
      _quoteFadeOutController.removeListener(_onFadeOutUpdate);
      setState(() {
        _showingQuote = false;
        _currentQuote = _nextQuote;  // NOW switch to new verse
        _quoteOpacity = 0.0;
        _newQuoteFadingIn = true; // NOW we're ready to fade in new quote
      });
    });
  }
  
  void _onFadeOutUpdate() {
    setState(() {
      _quoteOpacity = 1.0 - Curves.easeOut.transform(_quoteFadeOutController.value);
      
      // Start tiles moving when quote has faded to ~60% opacity
      if (!_tilesStarted && _quoteOpacity <= 0.6) {
        _tilesStarted = true;
        _startTileTransition();
      }
    });
  }
  
  void _startTileTransition() {
    // _targetComposition is already set by _pickNextVerseAndComposition()
    final targetTiles = compositionTiles[_targetComposition];
    
    // Add new tiles if needed (they enter from off-screen)
    for (int i = _tiles.length; i < targetTiles.length && i < maxTiles; i++) {
      final targetPos = Offset(
        targetTiles[i][1].toDouble(),
        targetTiles[i][0].toDouble(),
      );
      
      final startPos = Offset(
        _random.nextBool() ? -2 : gridSize.toDouble() + 1,
        targetPos.dy,
      );
      
      _tiles.add(TileState(
        id: i,
        currentPos: startPos,
        targetPos: targetPos,
        path: [],
        delay: 0,
        duration: 0.5,
        isVisible: true,
      ));
    }
    
    // Calculate chain reaction paths
    _calculateChainReactionPaths(targetTiles);
    
    // Find when the last tile finishes
    double latestTileEnd = 0;
    for (var tile in _tiles) {
      double tileEnd = tile.delay + tile.duration;
      if (tileEnd > latestTileEnd) latestTileEnd = tileEnd;
    }
    
    // Quote fades in during the last 40% of the last tile's movement
    // This ties them together perfectly
    _quoteStartTime = latestTileEnd * 0.6;  // Start at 60% of last tile
    _quoteEndTime = latestTileEnd;           // Fully visible when last tile lands
    // Don't set _newQuoteFadingIn yet - wait until old quote is fully gone
    
    _masterController.forward(from: 0);
  }

  @override
  void dispose() {
    _masterController.dispose();
    _quoteFadeOutController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _toggleSource() {
    if (_isTransitioning) return;

    setState(() {
      _showingSource = !_showingSource;
    });

    if (_showingSource) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _showOnboarding() {
    setState(() {
      _showingOnboarding = true;
      _onboardingPage = 0;
    });
  }

  void _nextOnboardingPage() {
    setState(() {
      if (_onboardingPage < OnboardingOverlay.pageCount - 1) {
        _onboardingPage++;
      } else {
        _showingOnboarding = false;
        _onboardingPage = 0;
      }
    });
  }

  void _dismissOnboarding() {
    setState(() {
      _showingOnboarding = false;
      _onboardingPage = 0;
    });
  }

  // === Smart verse/composition matching ===

  // Auto-wrap long text that doesn't have manual line breaks
  String _autoWrapText(String text, {int charsPerLine = 20}) {
    // If already has line breaks, leave it alone
    if (text.contains('\n')) {
      return text;
    }

    // If short enough, no wrapping needed
    if (text.length <= charsPerLine) {
      return text;
    }

    // Split into words and rebuild with line breaks
    final words = text.split(' ');
    final lines = <String>[];
    var currentLine = '';

    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if (currentLine.length + 1 + word.length <= charsPerLine) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines.join('\n');
  }

  // Calculate verse "size" based on line count after auto-wrapping
  // Returns: 0 = tiny, 1 = small, 2 = medium, 3 = large, 4 = extra large
  int _getVerseSize(Verse verse) {
    // Use auto-wrapped text to get accurate line count
    final wrappedText = _autoWrapText(verse.text);
    final lineCount = wrappedText.split('\n').length;

    if (lineCount <= 2) return 0;       // tiny
    if (lineCount <= 3) return 1;       // small
    if (lineCount <= 5) return 2;       // medium
    if (lineCount <= 7) return 3;       // large
    return 4;                           // extra large
  }

  // Get clearing area for a composition
  double _getClearingArea(int compositionIndex) {
    final clearing = _clearings[compositionIndex];
    return clearing.width * clearing.height;
  }

  // Find compositions that can fit a verse of given size
  List<int> _getCompatibleCompositions(int verseSize) {
    List<int> compatible = [];

    for (int i = 0; i < compositionTiles.length; i++) {
      final area = _getClearingArea(i);

      // Match verse size to minimum clearing area needed
      // Areas: small clearing ~6-8, medium ~10-12, large ~16-20
      bool fits = false;
      switch (verseSize) {
        case 0: // tiny - any clearing works
        case 1: // small - any clearing works
          fits = true;
          break;
        case 2: // medium - need at least 8 area
          fits = area >= 8;
          break;
        case 3: // large - need at least 12 area
          fits = area >= 12;
          break;
        case 4: // extra large - need biggest clearings (16+)
          fits = area >= 16;
          break;
      }

      if (fits) {
        compatible.add(i);
      }
    }

    // If nothing fits (shouldn't happen), return all compositions
    if (compatible.isEmpty) {
      return List.generate(compositionTiles.length, (i) => i);
    }

    return compatible;
  }

  // Pick a random verse and matching composition
  void _pickNextVerseAndComposition() {
    // Pick random verse (different from current)
    int newVerse;
    if (verses.length > 1) {
      do {
        newVerse = _random.nextInt(verses.length);
      } while (newVerse == _currentQuote);
    } else {
      newVerse = 0;
    }

    // Get verse size and find compatible compositions
    final verseSize = _getVerseSize(verses[newVerse]);
    final compatible = _getCompatibleCompositions(verseSize);

    // Pick random compatible composition (different from current if possible)
    int newComposition;
    final compatibleExcludingCurrent = compatible.where((c) => c != _currentComposition).toList();
    if (compatibleExcludingCurrent.isNotEmpty) {
      newComposition = compatibleExcludingCurrent[_random.nextInt(compatibleExcludingCurrent.length)];
    } else {
      newComposition = compatible[_random.nextInt(compatible.length)];
    }

    _nextQuote = newVerse;  // Store for later, don't update _currentQuote yet
    _targetComposition = newComposition;
  }

  // Get dynamic font size based on verse length
  double _getFontSize(Verse verse) {
    final size = _getVerseSize(verse);
    switch (size) {
      case 0: return 24;  // tiny
      case 1: return 22;  // small
      case 2: return 20;  // medium
      case 3: return 18;  // large
      case 4: return 16;  // extra large
      default: return 20;
    }
  }

  Widget _buildFlipContent() {
    final angle = _flipController.value * math.pi;
    final isFrontVisible = angle < math.pi / 2;

    // Auto-wrap text that doesn't have manual line breaks
    final displayText = _autoWrapText(verses[_currentQuote].text);
    final fontSize = _getFontSize(verses[_currentQuote]);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..rotateY(angle),
      child: isFrontVisible
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayText,
                textAlign: TextAlign.center,
                style: GoogleFonts.jost(
                  fontSize: fontSize,
                  height: 1.5,
                  color: const Color(0xFF2C2C2C),
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          : Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(math.pi),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SourceText(
                  source: verses[_currentQuote].source,
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          GestureDetector(
            onTap: _showingQuote && !_isTransitioning && !_showingOnboarding
                ? _transitionToNext
                : null,
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final controlsHeight = 60.0;
                    final padding = 24.0;
                    final availableWidth = constraints.maxWidth - (padding * 2);
                    final availableHeight = constraints.maxHeight - (padding * 2) - controlsHeight;
                    final squareSize = availableWidth < availableHeight ? availableWidth : availableHeight;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: squareSize,
                          height: squareSize,
                          child: _buildGrid(squareSize),
                        ),
                        SizedBox(
                          height: controlsHeight,
                          width: squareSize,
                          child: _buildControls(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // Onboarding overlay
          if (_showingOnboarding)
            OnboardingOverlay(
              currentPage: _onboardingPage,
              onTap: _nextOnboardingPage,
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(double size) {
    final clearing = _newQuoteFadingIn
        ? _clearings[_targetComposition]
        : _clearings[_currentComposition];

    final tileSize = size / 6; // gridSize is 6

    final clearingLeft = clearing.left * tileSize;
    final clearingTop = clearing.top * tileSize;
    final clearingWidth = clearing.width * tileSize;
    final clearingHeight = clearing.height * tileSize;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Quote/Source layer with 3D flip
        if (_showingQuote)
          Positioned(
            left: clearingLeft,
            top: clearingTop,
            width: clearingWidth,
            height: clearingHeight,
            child: Opacity(
              opacity: _quoteOpacity,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildFlipContent(),
                ),
              ),
            ),
          ),

        // Tiles layer
        ..._tiles.where((t) =>
            t.currentPos.dx >= -0.5 && t.currentPos.dx < 6.5 &&
            t.currentPos.dy >= -0.5 && t.currentPos.dy < 6.5
        ).map((tile) {
          return Positioned(
            left: tile.currentPos.dx * tileSize - 0.5,
            top: tile.currentPos.dy * tileSize - 0.5,
            child: Container(
              width: tileSize + 1,
              height: tileSize + 1,
              color: const Color(0xFF1A1A1A),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source/text toggle (left side)
        Padding(
          padding: const EdgeInsets.only(left: 4.0, top: 12.0),
          child: GestureDetector(
            onTap: _toggleSource,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  color: const Color(0xFFAAAAAA),
                ),
                const SizedBox(width: 8),
                Text(
                  _showingSource ? 'text' : 'source',
                  style: GoogleFonts.jost(
                    fontSize: 12,
                    color: const Color(0xFFAAAAAA),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Info icon (right side)
        Padding(
          padding: const EdgeInsets.only(right: 4.0, top: 10.0),
          child: GestureDetector(
            onTap: _showOnboarding,
            behavior: HitTestBehavior.opaque,
            child: Text(
              'i',
              style: GoogleFonts.jost(
                fontSize: 16,
                color: const Color(0xFFAAAAAA),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TileState {
  int id;
  Offset currentPos;
  Offset targetPos;
  List<Offset> path;
  double delay;
  double duration;
  bool isVisible;
  
  TileState({
    required this.id,
    required this.currentPos,
    required this.targetPos,
    required this.path,
    required this.delay,
    required this.duration,
    required this.isVisible,
  });
}