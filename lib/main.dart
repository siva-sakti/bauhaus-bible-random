import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  
  final Random _random = Random();
  
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
  
  final List<String> quotes = [
    "Be still,\nand know that\nI am God.",
    "The light shines\nin the darkness.",
    "For everything\nthere is a season.",
    "Love is patient,\nlove is kind.",
    "Ask, and it will\nbe given to you.",
  ];
  int _currentQuote = 0;

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
    _targetComposition = 0;
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
        // Tile needs to exit
        final exitTarget = Offset(
          _random.nextBool() ? -1 : gridSize.toDouble(),
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
    
    setState(() {
      _isTransitioning = true;
      _newQuoteFadingIn = false;
      _tilesStarted = false;
    });
    
    // Fade out current quote - tiles will start when opacity drops
    _quoteFadeOutController.addListener(_onFadeOutUpdate);
    _quoteFadeOutController.forward(from: 0).then((_) {
      _quoteFadeOutController.removeListener(_onFadeOutUpdate);
      setState(() {
        _showingQuote = false;
        _currentQuote = (_currentQuote + 1) % quotes.length;
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
    _targetComposition = (_currentComposition + 1) % compositionTiles.length;
    
    final targetTiles = compositionTiles[_targetComposition];
    
    // Add new tiles if needed (they enter from off-screen)
    for (int i = _tiles.length; i < targetTiles.length && i < maxTiles; i++) {
      final targetPos = Offset(
        targetTiles[i][1].toDouble(),
        targetTiles[i][0].toDouble(),
      );
      
      final startPos = Offset(
        _random.nextBool() ? -1 : gridSize.toDouble(),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Old quote fading out: use current composition's clearing
    // New quote fading in: use target composition's clearing  
    final clearing = _newQuoteFadingIn 
        ? _clearings[_targetComposition] 
        : _clearings[_currentComposition];
    
    return Scaffold(
      body: GestureDetector(
        onTap: _showingQuote && !_isTransitioning ? _transitionToNext : null,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gridWidth = constraints.maxWidth;
                  final tileSize = gridWidth / gridSize;
                  
                  final clearingLeft = clearing.left * tileSize;
                  final clearingTop = clearing.top * tileSize;
                  final clearingWidth = clearing.width * tileSize;
                  final clearingHeight = clearing.height * tileSize;
                  
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Quote layer
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
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    quotes[_currentQuote],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.jost(
                                      fontSize: 22,
                                      height: 1.5,
                                      color: const Color(0xFF2C2C2C),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      // Tiles layer
                      ..._tiles.where((t) => 
                          t.currentPos.dx >= -0.5 && t.currentPos.dx < gridSize + 0.5 &&
                          t.currentPos.dy >= -0.5 && t.currentPos.dy < gridSize + 0.5
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
                      
                      // Tap hint
                      if (_showingQuote && !_isTransitioning && _quoteOpacity > 0.8)
                        Positioned(
                          bottom: -40,
                          left: 0,
                          right: 0,
                          child: Opacity(
                            opacity: (_quoteOpacity - 0.8) * 5, // Fade in during last 20% of quote fade
                            child: Text(
                              'tap for another',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.jost(
                                fontSize: 12,
                                color: const Color(0xFFAAAAAA),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
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
