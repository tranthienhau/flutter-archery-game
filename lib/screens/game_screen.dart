import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../game/game_painter.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  DateTime _lastTick = DateTime.now();
  Offset? _aimPoint;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_onTick)
      ..repeat();
  }

  void _onTick() {
    final now = DateTime.now();
    final dt = now.difference(_lastTick).inMilliseconds / 1000.0;
    _lastTick = now;
    final notifier = ref.read(gameProvider.notifier);
    final size = MediaQuery.of(context).size;
    notifier.updateArrow(dt);
    notifier.updateTarget(dt, size);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A2332),
      body: SafeArea(
        child: Column(
          children: [
            _buildHUD(game),
            Expanded(
              child: GestureDetector(
                onTapDown: (d) => setState(() => _aimPoint = d.localPosition),
                onTapUp: (d) {
                  if (game.phase == GamePhase.aiming) {
                    ref.read(gameProvider.notifier).shoot(d.localPosition, size);
                  } else if (game.phase == GamePhase.scored) {
                    ref.read(gameProvider.notifier).nextArrow();
                    setState(() => _aimPoint = null);
                  } else if (game.phase == GamePhase.roundEnd) {
                    ref.read(gameProvider.notifier).nextRound();
                    setState(() => _aimPoint = null);
                  } else if (game.phase == GamePhase.gameOver) {
                    ref.read(gameProvider.notifier).reset();
                    setState(() => _aimPoint = null);
                  }
                },
                child: CustomPaint(
                  painter: GamePainter(game: game, aimPoint: _aimPoint),
                  size: Size.infinite,
                ),
              ),
            ),
            _buildWindIndicator(game),
            _buildStatusBar(game),
          ],
        ),
      ),
    );
  }

  Widget _buildHUD(GameState game) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Round ${game.round} / $kTotalRounds',
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text('Score: ${game.totalScore}',
              style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Arrows: ${game.arrowsThisRound} / $kArrowsPerRound',
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildWindIndicator(GameState game) {
    final wind = game.windStrength;
    final direction = wind > 0 ? 'RIGHT' : 'LEFT';
    final strength = (wind.abs() * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(wind > 0 ? Icons.arrow_forward : Icons.arrow_back,
              color: Colors.lightBlueAccent, size: 20),
          const SizedBox(width: 6),
          Text('Wind: $strength% $direction',
              style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatusBar(GameState game) {
    String message = '';
    switch (game.phase) {
      case GamePhase.aiming:
        message = 'Tap to aim and shoot';
        break;
      case GamePhase.flying:
        message = '...';
        break;
      case GamePhase.scored:
        message = '${game.lastHitLabel ?? ''} - Tap to continue';
        break;
      case GamePhase.roundEnd:
        message = 'Round ${game.round} complete! Tap for next round';
        break;
      case GamePhase.gameOver:
        message = 'GAME OVER! Total: ${game.totalScore} pts - Tap to restart';
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(message,
          style: TextStyle(
            color: game.phase == GamePhase.gameOver ? Colors.amber : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          )),
    );
  }
}
