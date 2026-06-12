import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_archery_game/models/game_state.dart';
import 'package:flutter_archery_game/screens/game_screen.dart';
import 'package:flutter_archery_game/screens/result_screen.dart';

// Seeds a finished game so the result screen renders real scores.
class _FinishedGameNotifier extends GameNotifier {
  @override
  GameState build() => const GameState(
        round: 3,
        arrowsThisRound: 3,
        roundScores: [26, 22, 28],
        totalScore: 76,
        phase: GamePhase.gameOver,
        windStrength: 0.3,
      );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The game screen runs an always-on animation ticker, so we pump a fixed
  // duration (never pumpAndSettle, which would hang on the infinite ticker).
  Future<void> shoot(WidgetTester tester, String name) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pump(const Duration(milliseconds: 400));
    await binding.takeScreenshot(name);
  }

  testWidgets('capture gameplay screens', (tester) async {
    // 01 - live aiming screen with HUD, moving target and wind indicator.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: GameScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await shoot(tester, '01-aiming');

    // Tap to loose an arrow, then let it fly toward the target.
    final canvas = find.byType(CustomPaint).first;
    await tester.tapAt(tester.getCenter(canvas));
    await tester.pump(const Duration(milliseconds: 250));
    await shoot(tester, '02-arrow-flying');
  });

  testWidgets('capture result screen', (tester) async {
    // 03 - game-over result screen seeded with a completed 3-round game.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameProvider.overrideWith(_FinishedGameNotifier.new),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ResultScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03-result');
  });
}
