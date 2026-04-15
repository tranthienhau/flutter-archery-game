import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF1A2332),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('GAME OVER',
                style: TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 4)),
            const SizedBox(height: 16),
            Text('${game.totalScore}',
                style: const TextStyle(color: Colors.amber, fontSize: 72, fontWeight: FontWeight.bold)),
            const Text('points', style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 32),
            ...List.generate(game.roundScores.length, (i) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('Round ${i + 1}: ${game.roundScores[i]} pts',
                    style: const TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ref.read(gameProvider.notifier).reset();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: const Text('PLAY AGAIN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
