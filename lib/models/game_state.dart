import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int kTotalRounds = 3;
const int kArrowsPerRound = 3;
const double kBullseyeRadius = 20.0;
const double kTargetRadius = 80.0;

enum GamePhase { aiming, flying, scored, roundEnd, gameOver }

class Arrow {
  final Offset start;
  final Offset target;
  final double windEffect;
  Offset current;
  double progress;

  Arrow({
    required this.start,
    required this.target,
    required this.windEffect,
    this.progress = 0.0,
  }) : current = start;

  void update(double dt) {
    progress = (progress + dt * 1.8).clamp(0.0, 1.0);
    final t = progress;
    final windDrift = windEffect * t * t * 80;
    final arcY = -sin(t * pi) * 60;
    current = Offset(
      start.dx + (target.dx - start.dx) * t + windDrift,
      start.dy + (target.dy - start.dy) * t + arcY,
    );
  }

  bool get isComplete => progress >= 1.0;
}

class GameState {
  final int round;
  final int arrowsThisRound;
  final List<int> roundScores;
  final int totalScore;
  final GamePhase phase;
  final double windStrength;
  final Offset targetCenter;
  final double targetVelocity;
  final Arrow? flyingArrow;
  final List<Offset> hitPositions;
  final String? lastHitLabel;

  const GameState({
    this.round = 1,
    this.arrowsThisRound = 0,
    this.roundScores = const [],
    this.totalScore = 0,
    this.phase = GamePhase.aiming,
    this.windStrength = 0.0,
    this.targetCenter = const Offset(200, 200),
    this.targetVelocity = 60,
    this.flyingArrow,
    this.hitPositions = const [],
    this.lastHitLabel,
  });

  GameState copyWith({
    int? round,
    int? arrowsThisRound,
    List<int>? roundScores,
    int? totalScore,
    GamePhase? phase,
    double? windStrength,
    Offset? targetCenter,
    double? targetVelocity,
    Arrow? flyingArrow,
    bool clearArrow = false,
    List<Offset>? hitPositions,
    String? lastHitLabel,
    bool clearHitLabel = false,
  }) {
    return GameState(
      round: round ?? this.round,
      arrowsThisRound: arrowsThisRound ?? this.arrowsThisRound,
      roundScores: roundScores ?? this.roundScores,
      totalScore: totalScore ?? this.totalScore,
      phase: phase ?? this.phase,
      windStrength: windStrength ?? this.windStrength,
      targetCenter: targetCenter ?? this.targetCenter,
      targetVelocity: targetVelocity ?? this.targetVelocity,
      flyingArrow: clearArrow ? null : flyingArrow ?? this.flyingArrow,
      hitPositions: hitPositions ?? this.hitPositions,
      lastHitLabel: clearHitLabel ? null : lastHitLabel ?? this.lastHitLabel,
    );
  }

  bool get isLastRound => round >= kTotalRounds;
  bool get roundComplete => arrowsThisRound >= kArrowsPerRound;

  static int calculateScore(Offset hit, Offset center) {
    final dist = (hit - center).distance;
    if (dist <= kBullseyeRadius) return 10;
    if (dist <= kBullseyeRadius * 2) return 8;
    if (dist <= kBullseyeRadius * 3) return 6;
    if (dist <= kTargetRadius) return 4;
    return 0;
  }

  static String scoreLabel(int score) {
    switch (score) {
      case 10: return 'BULLSEYE!';
      case 8: return 'INNER 8!';
      case 6: return 'GOOD!';
      case 4: return 'HIT!';
      default: return 'MISS!';
    }
  }
}

class GameNotifier extends Notifier<GameState> {
  final _random = Random();

  @override
  GameState build() => _newGame();

  GameState _newGame() => GameState(
    windStrength: (_random.nextDouble() * 2 - 1) * 0.6,
    targetCenter: Offset(160 + _random.nextDouble() * 80, 200),
    targetVelocity: 50 + _random.nextDouble() * 40,
  );

  void reset() => state = _newGame();

  void shoot(Offset aimPoint, Size screenSize) {
    if (state.phase != GamePhase.aiming) return;
    final bowPos = Offset(screenSize.width / 2, screenSize.height * 0.85);
    final arrow = Arrow(start: bowPos, target: aimPoint, windEffect: state.windStrength);
    state = state.copyWith(phase: GamePhase.flying, flyingArrow: arrow);
  }

  void updateArrow(double dt) {
    final arrow = state.flyingArrow;
    if (arrow == null || state.phase != GamePhase.flying) return;
    arrow.update(dt);
    state = state.copyWith(flyingArrow: arrow);
    if (arrow.isComplete) _resolveHit(arrow.current);
  }

  void updateTarget(double dt, Size screenSize) {
    if (state.phase != GamePhase.aiming && state.phase != GamePhase.flying) return;
    var nx = state.targetCenter.dx + state.targetVelocity * dt;
    double vel = state.targetVelocity;
    if (nx > screenSize.width - 60 || nx < 60) {
      vel = -vel;
      nx = state.targetCenter.dx + vel * dt;
    }
    state = state.copyWith(targetCenter: Offset(nx, state.targetCenter.dy), targetVelocity: vel);
  }

  void _resolveHit(Offset hitPoint) {
    final score = GameState.calculateScore(hitPoint, state.targetCenter);
    final label = GameState.scoreLabel(score);
    final newTotal = state.totalScore + score;
    final newArrows = state.arrowsThisRound + 1;
    final newHits = [...state.hitPositions, hitPoint];

    if (newArrows >= kArrowsPerRound) {
      final newRoundScores = [...state.roundScores, score];
      final phase = state.isLastRound ? GamePhase.gameOver : GamePhase.roundEnd;
      state = state.copyWith(
        totalScore: newTotal, arrowsThisRound: newArrows, roundScores: newRoundScores,
        hitPositions: newHits, lastHitLabel: label, phase: phase, clearArrow: true,
      );
    } else {
      state = state.copyWith(
        totalScore: newTotal, arrowsThisRound: newArrows, hitPositions: newHits,
        lastHitLabel: label, phase: GamePhase.scored, clearArrow: true,
      );
    }
  }

  void nextArrow() => state = state.copyWith(
    phase: GamePhase.aiming, clearHitLabel: true,
    windStrength: (_random.nextDouble() * 2 - 1) * 0.6,
  );

  void nextRound() => state = state.copyWith(
    round: state.round + 1, arrowsThisRound: 0, phase: GamePhase.aiming,
    hitPositions: [], clearHitLabel: true,
    windStrength: (_random.nextDouble() * 2 - 1) * 0.6,
    targetCenter: Offset(140 + _random.nextDouble() * 120, state.targetCenter.dy),
    targetVelocity: 50 + _random.nextDouble() * 60,
  );
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
