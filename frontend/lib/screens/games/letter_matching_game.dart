import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../services/progress_service.dart';

/// Pairs on the board for each level, in play order.
const List<int> letterMatchingLevelPairs = [3, 4, 6, 8];

const int letterMatchingStarsReward = 15;

class _MatchCard {
  final String letter; // Uppercase letter shared by both cards of a pair
  final String label; // What the card shows: 'A' or 'a'
  bool isFaceUp = false;
  bool isMatched = false;

  _MatchCard({required this.letter, required this.label});
}

/// Memory game: flip two cards to pair an uppercase letter with its lowercase.
class LetterMatchingGame extends StatefulWidget {
  final ProgressService progressService;

  const LetterMatchingGame({super.key, required this.progressService});

  @override
  State<LetterMatchingGame> createState() => _LetterMatchingGameState();
}

class _LetterMatchingGameState extends State<LetterMatchingGame> {
  static const _mismatchDelay = Duration(milliseconds: 900);
  static const _levelEndDelay = Duration(milliseconds: 600);

  final Random _random = Random();

  // Game states: 'playing', 'level_complete', 'victory'
  String _gameState = 'playing';
  int _levelIndex = 0;
  int _moves = 0;
  List<_MatchCard> _cards = [];
  _MatchCard? _firstPick;
  bool _boardLocked = false;
  Timer? _pendingTimer;

  @override
  void initState() {
    super.initState();
    _loadLevel(0);
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    super.dispose();
  }

  void _loadLevel(int levelIndex) {
    _pendingTimer?.cancel();
    final alphabet = List.generate(26, (i) => String.fromCharCode(65 + i))..shuffle(_random);
    final letters = alphabet.take(letterMatchingLevelPairs[levelIndex]);

    _levelIndex = levelIndex;
    _moves = 0;
    _firstPick = null;
    _boardLocked = false;
    _gameState = 'playing';
    _cards = [
      for (final letter in letters) ...[
        _MatchCard(letter: letter, label: letter),
        _MatchCard(letter: letter, label: letter.toLowerCase()),
      ],
    ]..shuffle(_random);
  }

  void _onCardTap(_MatchCard card) {
    if (_gameState != 'playing' || _boardLocked || card.isFaceUp || card.isMatched) return;

    final firstPick = _firstPick;
    if (firstPick == null) {
      setState(() {
        card.isFaceUp = true;
        _firstPick = card;
      });
      return;
    }

    setState(() {
      card.isFaceUp = true;
      _firstPick = null;
      _moves++;
    });

    if (firstPick.letter == card.letter) {
      setState(() {
        firstPick.isMatched = true;
        card.isMatched = true;
      });
      if (_cards.every((c) => c.isMatched)) {
        _boardLocked = true;
        _pendingTimer = Timer(_levelEndDelay, _finishLevel);
      }
      return;
    }

    _boardLocked = true;
    _pendingTimer = Timer(_mismatchDelay, () {
      if (!mounted) return;
      setState(() {
        firstPick.isFaceUp = false;
        card.isFaceUp = false;
        _boardLocked = false;
      });
    });
  }

  void _finishLevel() {
    if (!mounted) return;
    final isLastLevel = _levelIndex == letterMatchingLevelPairs.length - 1;
    if (isLastLevel) {
      widget.progressService.recordGameCompleted(letterMatchingStarsReward);
    }
    setState(() {
      _gameState = isLastLevel ? 'victory' : 'level_complete';
    });
  }

  void _restartLevel() => setState(() => _loadLevel(_levelIndex));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8338EC), Color(0xFF3A86FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(context),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Find the big and small letter pairs!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: _buildBoard()),
                    ],
                  ),
                  if (_gameState != 'playing') _buildResultOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              'Level ${_levelIndex + 1} of ${letterMatchingLevelPairs.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            'Moves: $_moves',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            tooltip: 'Restart level',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _restartLevel,
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    const spacing = 10.0;
    const padding = 16.0;
    final columns = _cards.length <= 8 ? 2 : (_cards.length <= 12 ? 3 : 4);
    final rows = (_cards.length / columns).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Size the cards so a whole level fits on screen without scrolling.
        final cardWidth = (constraints.maxWidth - padding * 2 - spacing * (columns - 1)) / columns;
        final cardHeight = (constraints.maxHeight - padding * 2 - spacing * (rows - 1)) / rows;

        return GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(padding),
          crossAxisCount: columns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: cardWidth / cardHeight,
          children: [for (final card in _cards) _buildCard(card)],
        );
      },
    );
  }

  Widget _buildCard(_MatchCard card) {
    return GestureDetector(
      key: ValueKey('match_card_${card.label}'),
      onTap: () => _onCardTap(card),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: card.isFaceUp ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 260),
        builder: (context, flip, _) {
          final showFront = flip >= 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(pi * (showFront ? flip - 1 : flip)),
            child: showFront ? _buildCardFront(card) : _buildCardBack(),
          );
        },
      ),
    );
  }

  Widget _buildCardFront(_MatchCard card) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: card.isMatched ? const Color(0xFFDCFCE7) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: card.isMatched ? const Color(0xFF16A34A) : Colors.white,
          width: 3,
        ),
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            card.label,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: card.isMatched ? const Color(0xFF15803D) : const Color(0xFF5B21B6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD166), Color(0xFFFF9F1C)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Icon(Icons.star_rounded, color: Colors.white, size: 36),
    );
  }

  Widget _buildResultOverlay() {
    final isVictory = _gameState == 'victory';

    return Positioned.fill(
      child: Container(
        alignment: Alignment.center,
        color: Colors.black.withValues(alpha: 0.55),
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 64),
              const SizedBox(height: 8),
              Text(
                isVictory ? 'You matched them all!' : 'Level ${_levelIndex + 1} complete!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isVictory ? '+$letterMatchingStarsReward stars' : 'Finished in $_moves moves',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => setState(() => _loadLevel(isVictory ? 0 : _levelIndex + 1)),
                child: Text(isVictory ? 'Play Again' : 'Next Level'),
              ),
              if (isVictory)
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Back to Games'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
