import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/verse.dart';
import 'features/onboarding.dart';
import 'features/compositions_test.dart';

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
  
  static const int gridSize = 10;

  // TEST MODE: Use compositions from test file
  final List<List<List<int>>> compositionTiles = testCompositions;

  // ORIGINAL COMPOSITIONS (commented out for testing)
  /*
  final List<List<List<int>>> compositionTiles = [
    // Diagonal cascade — dense top-right
    [
      // Full top rows
      [0, 0], [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7], [0, 8], [0, 9],
      [1, 0], [1, 1], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7], [1, 8], [1, 9],
      // Stepping down densely
      [2, 3], [2, 4], [2, 5], [2, 6], [2, 7], [2, 8], [2, 9],
      [3, 4], [3, 5], [3, 6], [3, 7], [3, 8], [3, 9],
      [4, 5], [4, 6], [4, 7], [4, 8], [4, 9],
      [5, 6], [5, 7], [5, 8], [5, 9],
      [6, 7], [6, 8], [6, 9],
      [7, 8], [7, 9],
      [8, 9],
    ],

    // Bottom-heavy — sand settled at bottom
    [
      // Scattered top particles
      [0, 1], [0, 5], [0, 8],
      [1, 0], [1, 3], [1, 6], [1, 9],
      [2, 2], [2, 4], [2, 7],
      // Dense middle-bottom
      [5, 0], [5, 1], [5, 8], [5, 9],
      [6, 0], [6, 1], [6, 2], [6, 7], [6, 8], [6, 9],
      [7, 0], [7, 1], [7, 2], [7, 3], [7, 6], [7, 7], [7, 8], [7, 9],
      [8, 0], [8, 1], [8, 2], [8, 3], [8, 4], [8, 5], [8, 6], [8, 7], [8, 8], [8, 9],
      [9, 0], [9, 1], [9, 2], [9, 3], [9, 4], [9, 5], [9, 6], [9, 7], [9, 8], [9, 9],
    ],

    // Thick frame — double border
    [
      // Top two rows
      [0, 0], [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7], [0, 8], [0, 9],
      [1, 0], [1, 1], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7], [1, 8], [1, 9],
      // Thick sides
      [2, 0], [2, 1], [2, 8], [2, 9],
      [3, 0], [3, 1], [3, 8], [3, 9],
      [4, 0], [4, 1], [4, 8], [4, 9],
      [5, 0], [5, 1], [5, 8], [5, 9],
      [6, 0], [6, 1], [6, 8], [6, 9],
      [7, 0], [7, 1], [7, 8], [7, 9],
      // Bottom two rows
      [8, 0], [8, 1], [8, 2], [8, 3], [8, 4], [8, 5], [8, 6], [8, 7], [8, 8], [8, 9],
      [9, 0], [9, 1], [9, 2], [9, 3], [9, 4], [9, 5], [9, 6], [9, 7], [9, 8], [9, 9],
    ],

    // Corner masses — solid rectangular blocks
    [
      // Top-left block (5x4)
      [0, 0], [0, 1], [0, 2], [0, 3],
      [1, 0], [1, 1], [1, 2], [1, 3],
      [2, 0], [2, 1], [2, 2], [2, 3],
      [3, 0], [3, 1], [3, 2], [3, 3],
      [4, 0], [4, 1], [4, 2], [4, 3],
      // Bottom-right block (5x4)
      [5, 6], [5, 7], [5, 8], [5, 9],
      [6, 6], [6, 7], [6, 8], [6, 9],
      [7, 6], [7, 7], [7, 8], [7, 9],
      [8, 6], [8, 7], [8, 8], [8, 9],
      [9, 6], [9, 7], [9, 8], [9, 9],
    ],
  ];
  */

  List<Rect> _clearings = [];

  // SEQUENTIAL TEST MODE: Cycle through all compositions in order (ignores verse matching)
  static const bool _sequentialTestMode = false;  // OFF for normal use
  static const int _testStartIndex = 0;  // Set to 0 for all, or 26 to start at new batch (#32+)

  int _currentComposition = _testStartIndex > 0 ? _testStartIndex - 1 : 0;  // Start before test range
  int _targetComposition = _testStartIndex > 0 ? _testStartIndex : 1;
  bool _showingQuote = false;
  bool _isTransitioning = false;
  bool _newQuoteFadingIn = false; // Track when fading IN the new quote
  
  List<TileState> _tiles = [];
  
  static const int maxTiles = 70;  // More tiles for 10x10 grid (thick frames need ~64)
  
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

  // More view state
  bool _isMoreViewActive = false;
  bool _isMoreTransitioning = false;
  late AnimationController _moreTransitionController;
  late AnimationController _breathingController;
  late Animation<double> _tileShrinkAnimation;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();

    for (var tiles in compositionTiles) {
      _clearings.add(_findLargestClearing(tiles));
    }

    // Manual clearing overrides for better text centering
    // These compositions have asymmetric white space where auto-detection doesn't center well
    _applyManualClearingOverrides();

    _masterController = AnimationController(
      duration: const Duration(milliseconds: 8000), // Slower, more contemplative
      vsync: this,
    );

    _quoteFadeOutController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _flipController.addListener(() => setState(() {}));

    // More view animation controllers
    _moreTransitionController = AnimationController(
      duration: const Duration(milliseconds: 900), // Slower detail page transition
      vsync: this,
    );
    _moreTransitionController.addListener(() => setState(() {}));

    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
    _breathingController.addListener(() => setState(() {}));

    _tileShrinkAnimation = CurvedAnimation(
      parent: _moreTransitionController,
      curve: Curves.easeInOutSine,  // Very gentle, smooth curve
    );

    _breathingAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

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

  // Manual clearing overrides for compositions where auto-detection doesn't center text well
  void _applyManualClearingOverrides() {
    // Note: Array indices shift because some compositions are commented out

    // #4 (Top-left block 5x5) → index 4
    // Block at rows 0-4, cols 0-4. Text should be in bottom-right area.
    if (_clearings.length > 4) {
      _clearings[4] = const Rect.fromLTWH(5, 5, 5, 5);  // Bottom-right quadrant
    }

    // #5 (Bottom-right block 5x5) → index 5
    // Block at rows 5-9, cols 5-9. Text should be in top-left area.
    if (_clearings.length > 5) {
      _clearings[5] = const Rect.fromLTWH(0, 0, 5, 5);  // Top-left quadrant
    }

    // #6 (Top-right block 5x5) → index 6
    // Block at rows 0-4, cols 5-9. Text should be in bottom-left area.
    if (_clearings.length > 6) {
      _clearings[6] = const Rect.fromLTWH(0, 5, 5, 5);  // Bottom-left quadrant
    }

    // #12 (Diagonal corners TL+BR) → index 11: center text between the two blocks
    if (_clearings.length > 11) {
      _clearings[11] = const Rect.fromLTWH(2, 2, 6, 6);  // Centers at (5, 5) - true center
    }

    // #13 (Diagonal corners TR+BL) → index 12: center text between the two blocks
    if (_clearings.length > 12) {
      _clearings[12] = const Rect.fromLTWH(2, 2, 6, 6);  // Centers at (5, 5) - true center
    }
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
    double delayPerDepth = 0.06; // Each chain level adds this much delay (faster for more tiles)
    double baseMoveDuration = 0.40; // How long each tile takes to move (snappier for fine grid)
    
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
    if (_isTransitioning || _isMoreTransitioning) return;

    // Exit more view if active
    if (_isMoreViewActive) {
      _exitMoreView();
      return;
    }

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
    _moreTransitionController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _toggleSource() {
    if (_isTransitioning || _isMoreViewActive || _isMoreTransitioning) return;

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

  // === More view functions ===

  void _toggleMoreView() {
    // Don't allow toggle if no extra content or during transitions
    if (!verses[_currentQuote].hasMore) return;
    if (_isTransitioning || _isMoreTransitioning) return;

    if (_isMoreViewActive) {
      _exitMoreView();
    } else {
      _enterMoreView();
    }
  }

  void _enterMoreView() {
    // Reset source view if showing
    if (_showingSource) {
      _showingSource = false;
      _flipController.reset();
    }

    setState(() {
      _isMoreTransitioning = true;
      _isMoreViewActive = true;
    });

    // Start breathing animation
    _breathingController.repeat(reverse: true);

    _moreTransitionController.forward().then((_) {
      setState(() {
        _isMoreTransitioning = false;
      });
    });
  }

  void _exitMoreView() {
    setState(() {
      _isMoreTransitioning = true;
      _isMoreViewActive = false;  // Set to false NOW so isExiting works
    });

    // Stop breathing animation
    _breathingController.stop();

    _moreTransitionController.reverse().then((_) {
      setState(() {
        _isMoreTransitioning = false;
      });
    });
  }

  // === Tiny tile helpers for "more" view ===

  // Configuration for tiny tiles (bookends at top and bottom)
  static const int _tinyGridSize = 20;  // Finer bookends for 10x10 grid
  static const double _tinyTileGap = 0.4; // Gap between tiny tiles (0-1, portion of tile size)

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
    final wrappedText = _autoWrapText(verse.anchor);
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

  // Calculate movement score between two compositions
  // Higher score = more tile movement (more visual interest)
  double _getMovementScore(int fromIndex, int toIndex) {
    final fromTiles = compositionTiles[fromIndex];
    final toTiles = compositionTiles[toIndex];

    // Create sets of positions for quick lookup
    final fromPositions = fromTiles.map((t) => '${t[0]},${t[1]}').toSet();
    final toPositions = toTiles.map((t) => '${t[0]},${t[1]}').toSet();

    // Count tiles that need to move (not in same position)
    final stationaryTiles = fromPositions.intersection(toPositions).length;
    final movingTiles = fromTiles.length + toTiles.length - (2 * stationaryTiles);

    // Calculate average distance tiles must travel
    double totalDistance = 0;
    for (final fromTile in fromTiles) {
      if (!toPositions.contains('${fromTile[0]},${fromTile[1]}')) {
        // Find nearest destination position
        double minDist = double.infinity;
        for (final toTile in toTiles) {
          final dist = (fromTile[0] - toTile[0]).abs() + (fromTile[1] - toTile[1]).abs();
          if (dist < minDist) minDist = dist.toDouble();
        }
        totalDistance += minDist;
      }
    }

    // Score combines: tiles that move + average distance
    return movingTiles + totalDistance;
  }

  // Find compositions that can fit a verse of given size
  List<int> _getCompatibleCompositions(int verseSize) {
    List<int> compatible = [];

    for (int i = 0; i < compositionTiles.length; i++) {
      final area = _getClearingArea(i);

      // Match verse size to minimum clearing area needed
      // For 10x10 grid (100 total area), scale thresholds proportionally
      bool fits = false;
      switch (verseSize) {
        case 0: // tiny - any clearing works
        case 1: // small - any clearing works
          fits = true;
          break;
        case 2: // medium - need at least ~20% of grid
          fits = area >= 20;
          break;
        case 3: // large - need at least ~30% of grid
          fits = area >= 30;
          break;
        case 4: // extra large - need biggest clearings (~40%+)
          fits = area >= 40;
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
    // SEQUENTIAL TEST MODE: Cycle through compositions in order (from _testStartIndex)
    if (_sequentialTestMode) {
      // Next composition in sequence (wraps to start index, not 0)
      int newComposition = _currentComposition + 1;
      if (newComposition >= compositionTiles.length) {
        newComposition = _testStartIndex;  // Wrap back to start of test range
      }

      // Pick random verse (different from current) - verse matching disabled in test mode
      int newVerse;
      if (verses.length > 1) {
        do {
          newVerse = _random.nextInt(verses.length);
        } while (newVerse == _currentQuote);
      } else {
        newVerse = 0;
      }

      _nextQuote = newVerse;
      _targetComposition = newComposition;
      return;
    }

    // NORMAL MODE: Prefer high-movement compositions with verse-size matching
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

    // Exclude recently used compositions
    final excludeList = {_currentComposition, _targetComposition};
    final candidates = compatible.where((c) => !excludeList.contains(c)).toList();

    int newComposition;
    if (candidates.length <= 1) {
      // Not enough candidates, just pick what we can
      newComposition = candidates.isNotEmpty
          ? candidates[0]
          : compatible[_random.nextInt(compatible.length)];
    } else {
      // Score each candidate by movement from current composition
      final scored = <MapEntry<int, double>>[];
      for (final c in candidates) {
        scored.add(MapEntry(c, _getMovementScore(_currentComposition, c)));
      }

      // Sort by score descending (highest movement first)
      scored.sort((a, b) => b.value.compareTo(a.value));

      // Pick randomly from top third (ensures variety while favoring movement)
      final topCount = (scored.length / 3).ceil().clamp(1, scored.length);
      final topMovers = scored.take(topCount).map((e) => e.key).toList();
      newComposition = topMovers[_random.nextInt(topMovers.length)];
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

    // Auto-wrap anchor text that doesn't have manual line breaks
    final displayText = _autoWrapText(verses[_currentQuote].anchor);
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
            onTap: _showingQuote && !_isTransitioning && !_showingOnboarding && !_isMoreViewActive && !_isMoreTransitioning
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

    final normalTileSize = size / gridSize;
    final tinyTileSize = size / _tinyGridSize;

    final clearingLeft = clearing.left * normalTileSize;
    final clearingTop = clearing.top * normalTileSize;
    final clearingWidth = clearing.width * normalTileSize;
    final clearingHeight = clearing.height * normalTileSize;

    final moreProgress = _tileShrinkAnimation.value;
    final isEntering = _isMoreTransitioning && _isMoreViewActive;
    final isExiting = _isMoreTransitioning && !_isMoreViewActive;
    final isFullyInMoreView = _isMoreViewActive && !_isMoreTransitioning;

    final breathingScale = isFullyInMoreView ? _breathingAnimation.value : 1.0;

    // STATE 1: Normal view (no more view active)
    if (!_isMoreViewActive && !_isMoreTransitioning) {
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Quote in clearing
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
          // Tiles on top
          ..._buildNormalTiles(normalTileSize),
        ],
      );
    }

    // STATE 2: Entering more view
    // Phase 1 (0-0.4): Tiles shrink + fade to 70%, anchor fades out
    // Phase 2 (0.33-0.83): Tiles drift to bookend positions
    // Phase 3 (0.67-1.0): Full text fades in
    if (isEntering) {
      // Anchor fade out (0 - 0.5) and content fade in (0.3 - 0.8) — overlapping
      final anchorOpacity = (1 - (moreProgress / 0.5)).clamp(0.0, 1.0);
      final contentOpacity = ((moreProgress - 0.3) / 0.5).clamp(0.0, 1.0);

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // More content fading in (behind tiles)
          Opacity(
            opacity: contentOpacity,
            child: _buildMoreContent(),
          ),

          // Anchor text fading out
          if (_showingQuote && anchorOpacity > 0)
            Positioned(
              left: clearingLeft,
              top: clearingTop,
              width: clearingWidth,
              height: clearingHeight,
              child: Opacity(
                opacity: _quoteOpacity * anchorOpacity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildFlipContent(),
                  ),
                ),
              ),
            ),

          // Tiles: shrinking, fading, drifting to bookends
          ..._buildEnteringTiles(normalTileSize, tinyTileSize, size, moreProgress),
        ],
      );
    }

    // STATE 3: Fully in more view
    if (isFullyInMoreView) {
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // More content
          _buildMoreContent(),
          // Bookends with breathing
          ..._buildBookendTiles(size, tinyTileSize, 1.0, breathingScale),
        ],
      );
    }

    // STATE 4: Exiting more view
    // Phase 1 (0-0.3): More text fades out
    // Phase 2 (0.22-0.9): Tiles grow + drift back to composition
    // Phase 3 (0.75-1.0): Anchor text fades in
    if (isExiting) {
      // moreProgress goes from 1.0 -> 0.0 during exit
      final exitProgress = 1 - moreProgress; // 0.0 -> 1.0

      // Content fade out (0 - 0.5) and anchor fade in (0.3 - 0.8) — overlapping
      final contentOpacity = (1 - (exitProgress / 0.5)).clamp(0.0, 1.0);
      final anchorOpacity = ((exitProgress - 0.3) / 0.5).clamp(0.0, 1.0);

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // More content fading out
          if (contentOpacity > 0)
            Opacity(
              opacity: contentOpacity,
              child: _buildMoreContent(),
            ),

          // Anchor text fading in
          if (_showingQuote && anchorOpacity > 0)
            Positioned(
              left: clearingLeft,
              top: clearingTop,
              width: clearingWidth,
              height: clearingHeight,
              child: Opacity(
                opacity: _quoteOpacity * anchorOpacity,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildFlipContent(),
                  ),
                ),
              ),
            ),

          // Tiles: growing, drifting from bookends back to composition
          ..._buildExitingTiles(normalTileSize, tinyTileSize, size, exitProgress),
        ],
      );
    }

    // Fallback (shouldn't reach here)
    return const SizedBox();
  }

  // Helper: Build tiles entering more view (shrink + fade + drift to bookends)
  // The big tiles BECOME the tiny tiles - continuous transformation
  List<Widget> _buildEnteringTiles(double normalSize, double tinySize, double gridPixelSize, double progress) {
    final tiles = _tiles.where((tile) =>
        tile.currentPos.dx >= -0.5 && tile.currentPos.dx < gridSize + 0.5 &&
        tile.currentPos.dy >= -0.5 && tile.currentPos.dy < gridSize + 0.5
    ).toList();

    if (tiles.isEmpty) return [];

    // Target tile size in bookend (with gaps)
    final gapSize = tinySize * _tinyTileGap;
    final targetSize = tinySize - gapSize;

    return tiles.asMap().entries.map((entry) {
      final index = entry.key;
      final tile = entry.value;

      // Random stagger: 0-80ms = 0-0.118 normalized (with 680ms total)
      // Use deterministic "random" based on tile id for consistency
      final stagger = ((tile.id * 37) % 80) / 680.0;

      // Adjust progress for this tile's stagger
      final tileProgress = ((progress - stagger) / (1.0 - stagger)).clamp(0.0, 1.0);

      // Apply easeOutCubic for size and position
      final easedProgress = Curves.easeOutCubic.transform(tileProgress);

      // Opacity dip: 1.0 → 0.5 (at 40%) → 0.85 (at end)
      double currentOpacity;
      if (tileProgress < 0.4) {
        // Fade from 1.0 to 0.5
        currentOpacity = lerpDouble(1.0, 0.5, tileProgress / 0.4)!;
      } else {
        // Fade from 0.5 to 0.85
        currentOpacity = lerpDouble(0.5, 0.85, (tileProgress - 0.4) / 0.6)!;
      }

      // Start position (composition)
      final startX = tile.currentPos.dx * normalSize;
      final startY = tile.currentPos.dy * normalSize;

      // Determine which bookend this tile goes to based on its Y position
      final isTopHalf = tile.currentPos.dy < gridSize / 2;

      // Calculate evenly-spaced position in bookend
      int bookendIndex;
      if (isTopHalf) {
        // Count how many tiles with lower index are also in top half
        bookendIndex = tiles.take(index).where((t) => t.currentPos.dy < gridSize / 2).length;
      } else {
        // Count how many tiles with lower index are also in bottom half
        bookendIndex = tiles.take(index).where((t) => t.currentPos.dy >= gridSize / 2).length;
      }

      // Count total tiles in this bookend
      final tilesInThisBookend = isTopHalf
          ? tiles.where((t) => t.currentPos.dy < gridSize / 2).length
          : tiles.where((t) => t.currentPos.dy >= gridSize / 2).length;

      // End position: evenly spaced across the width
      final spacing = gridPixelSize / tilesInThisBookend;
      final endX = bookendIndex * spacing + spacing / 2 - targetSize / 2;
      final endY = isTopHalf
          ? gapSize / 2  // Top bookend
          : gridPixelSize - tinySize + gapSize / 2;  // Bottom bookend

      // Interpolate position and size
      final currentX = lerpDouble(startX, endX, easedProgress)!;
      final currentY = lerpDouble(startY, endY, easedProgress)!;
      final currentSize = lerpDouble(normalSize, targetSize, easedProgress)!;

      return Positioned(
        left: currentX - 0.5,
        top: currentY - 0.5,
        child: Opacity(
          opacity: currentOpacity,
          child: Container(
            width: currentSize + 1,
            height: currentSize + 1,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      );
    }).toList();
  }

  // Helper: Build tiles exiting more view (grow + drift from bookends to composition)
  // The tiny tiles BECOME the big tiles - continuous transformation (reverse of entry)
  List<Widget> _buildExitingTiles(double normalSize, double tinySize, double gridPixelSize, double progress) {
    final tiles = _tiles.where((tile) =>
        tile.currentPos.dx >= -0.5 && tile.currentPos.dx < gridSize + 0.5 &&
        tile.currentPos.dy >= -0.5 && tile.currentPos.dy < gridSize + 0.5
    ).toList();

    if (tiles.isEmpty) return [];

    // Target tile size in bookend (with gaps)
    final gapSize = tinySize * _tinyTileGap;
    final startSize = tinySize - gapSize;

    return tiles.asMap().entries.map((entry) {
      final index = entry.key;
      final tile = entry.value;

      // Random stagger: 0-100ms = 0-0.147 normalized (with 680ms total)
      // Use deterministic "random" based on tile id for consistency
      final stagger = ((tile.id * 41) % 100) / 680.0;

      // Adjust progress for this tile's stagger
      final tileProgress = ((progress - stagger) / (1.0 - stagger)).clamp(0.0, 1.0);

      // Apply easeOutCubic for size and position
      final easedProgress = Curves.easeOutCubic.transform(tileProgress);

      // Opacity: 0.85 → 0.5 (at 40%) → 1.0 (reverse of entry dip)
      double currentOpacity;
      if (tileProgress < 0.4) {
        // Fade from 0.85 to 0.5
        currentOpacity = lerpDouble(0.85, 0.5, tileProgress / 0.4)!;
      } else {
        // Fade from 0.5 to 1.0
        currentOpacity = lerpDouble(0.5, 1.0, (tileProgress - 0.4) / 0.6)!;
      }

      // Determine which bookend this tile comes from based on its Y position
      final isTopHalf = tile.currentPos.dy < gridSize / 2;

      // Calculate evenly-spaced starting position in bookend
      int bookendIndex;
      if (isTopHalf) {
        bookendIndex = tiles.take(index).where((t) => t.currentPos.dy < gridSize / 2).length;
      } else {
        bookendIndex = tiles.take(index).where((t) => t.currentPos.dy >= gridSize / 2).length;
      }

      // Count total tiles in this bookend
      final tilesInThisBookend = isTopHalf
          ? tiles.where((t) => t.currentPos.dy < gridSize / 2).length
          : tiles.where((t) => t.currentPos.dy >= gridSize / 2).length;

      // Start position: evenly spaced in bookend
      final spacing = gridPixelSize / tilesInThisBookend;
      final startX = bookendIndex * spacing + spacing / 2 - startSize / 2;
      final startY = isTopHalf
          ? gapSize / 2  // Top bookend
          : gridPixelSize - tinySize + gapSize / 2;  // Bottom bookend

      // End position (composition)
      final endX = tile.currentPos.dx * normalSize;
      final endY = tile.currentPos.dy * normalSize;

      // Interpolate position and size
      final currentX = lerpDouble(startX, endX, easedProgress)!;
      final currentY = lerpDouble(startY, endY, easedProgress)!;
      final currentSize = lerpDouble(startSize, normalSize, easedProgress)!;

      return Positioned(
        left: currentX - 0.5,
        top: currentY - 0.5,
        child: Opacity(
          opacity: currentOpacity,
          child: Container(
            width: currentSize + 1,
            height: currentSize + 1,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      );
    }).toList();
  }

  // Helper: Build tiles at their normal positions
  List<Widget> _buildNormalTiles(double tileSize, {double opacity = 1.0}) {
    return _tiles.where((tile) =>
        tile.currentPos.dx >= -0.5 && tile.currentPos.dx < gridSize + 0.5 &&
        tile.currentPos.dy >= -0.5 && tile.currentPos.dy < gridSize + 0.5
    ).map((tile) {
      return Positioned(
        left: tile.currentPos.dx * tileSize - 0.5,
        top: tile.currentPos.dy * tileSize - 0.5,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: tileSize + 1,
            height: tileSize + 1,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      );
    }).toList();
  }

  // Build bookend tiles at top and bottom - matches the final state of entering animation
  // Uses actual composition tiles, evenly spaced
  List<Widget> _buildBookendTiles(double gridPixelSize, double tinyTileSize, double progress, double breathingScale) {
    final tiles = _tiles.where((tile) =>
        tile.currentPos.dx >= -0.5 && tile.currentPos.dx < gridSize + 0.5 &&
        tile.currentPos.dy >= -0.5 && tile.currentPos.dy < gridSize + 0.5
    ).toList();

    if (tiles.isEmpty) return [];

    final gapSize = tinyTileSize * _tinyTileGap;
    final baseSize = tinyTileSize - gapSize;
    final actualTileSize = baseSize * breathingScale;

    // Count tiles in each bookend
    final topTiles = tiles.where((t) => t.currentPos.dy < gridSize / 2).toList();
    final bottomTiles = tiles.where((t) => t.currentPos.dy >= gridSize / 2).toList();

    final List<Widget> result = [];

    // Top bookend
    for (int i = 0; i < topTiles.length; i++) {
      final spacing = gridPixelSize / topTiles.length;
      final x = i * spacing + spacing / 2 - actualTileSize / 2;
      final y = gapSize / 2;

      result.add(
        Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: progress * 0.85,  // Match final opacity from entering animation
            child: Container(
              width: actualTileSize,
              height: actualTileSize,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
      );
    }

    // Bottom bookend
    for (int i = 0; i < bottomTiles.length; i++) {
      final spacing = gridPixelSize / bottomTiles.length;
      final x = i * spacing + spacing / 2 - actualTileSize / 2;
      final y = gridPixelSize - tinyTileSize + gapSize / 2;

      result.add(
        Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: progress * 0.85,  // Match final opacity from entering animation
            child: Container(
              width: actualTileSize,
              height: actualTileSize,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
      );
    }

    return result;
  }

  // Build the scrollable content for more view (no internal fade - parent handles opacity)
  Widget _buildMoreContent() {
    final verse = verses[_currentQuote];

    return GestureDetector(
      onTap: _exitMoreView,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 40, // Space for top bookend
          bottom: 40, // Space for bottom bookend
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Full text (or anchor if no full text)
              Text(
                verse.full ?? verse.anchor,
                textAlign: TextAlign.center,
                style: GoogleFonts.jost(
                  fontSize: 18,
                  height: 1.6,
                  color: const Color(0xFF2C2C2C),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 24),

              // Source
              Text(
                verse.source,
                textAlign: TextAlign.center,
                style: GoogleFonts.jost(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF888888),
                  letterSpacing: 0.5,
                ),
              ),

              // Commentary (if available)
              if (verse.commentary != null) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3EE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    verse.commentary!,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.jost(
                      fontSize: 15,
                      height: 1.5,
                      color: const Color(0xFF555555),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    final hasMore = verses[_currentQuote].hasMore;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source and More toggles (left side)
        Padding(
          padding: const EdgeInsets.only(left: 4.0, top: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Source toggle (filled square)
              GestureDetector(
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

              const SizedBox(width: 20),

              // More toggle (outlined square)
              GestureDetector(
                onTap: hasMore ? _toggleMoreView : null,
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: hasMore ? 1.0 : 0.3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFAAAAAA),
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isMoreViewActive ? 'less' : 'more',
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
            ],
          ),
        ),

        // Composition number (center) + Info icon (right)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Composition number for testing
            Text(
              '#$_currentComposition',
              style: GoogleFonts.jost(
                fontSize: 12,
                color: const Color(0xFFAAAAAA),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 16),
            // Info icon
            Padding(
              padding: const EdgeInsets.only(right: 4.0, top: 0.0),
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