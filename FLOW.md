# Screenshot capture flow

Real captures from the iOS Simulator via an integration-test driver (no mockups).

## Steps

1. Boot the simulator:
   ```bash
   xcrun simctl boot "iPhone 17 Pro"
   open -a Simulator
   ```
2. Scaffold the iOS platform folder (lib-only project) and get dependencies:
   ```bash
   flutter create . --platforms=ios --project-name flutter_archery_game
   flutter pub get
   ```
3. Drive the screenshot test:
   ```bash
   flutter drive \
     --driver test_driver/integration_test.dart \
     --target integration_test/screenshot_test.dart \
     -d "iPhone 17 Pro"
   ```
4. Build the demo GIF from the PNGs:
   ```bash
   cd screenshots
   ffmpeg -y -framerate 1 -pattern_type glob -i '*.png' \
     -vf "scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
     -loop 0 demo.gif
   ```

PNGs + `demo.gif` are written to `screenshots/` and embedded in `README.md`.

## How it works

- `test_driver/integration_test.dart` - `integrationDriver(onScreenshot:)` writes each PNG to `screenshots/<name>.png`.
- `integration_test/screenshot_test.dart` - two test cases drive the app:
  - "capture gameplay screens" pumps `GameScreen`. Because the screen runs an always-on animation ticker (arrow physics + moving target), it pumps a fixed `Duration` (never `pumpAndSettle`, which would hang on the infinite ticker). It captures `01-aiming` (HUD, moving target, wind indicator), then taps the canvas to loose an arrow and captures `02-arrow-flying` (arrow resolved against the target with the hit label and updated arrow count).
  - "capture result screen" pumps `ResultScreen` inside a `ProviderScope` that overrides `gameProvider` with a seeded, finished game (3 rounds, scores 26/22/28, total 76) so the game-over screen renders real content, then captures `03-result`.
- Each shot calls `binding.convertFlutterSurfaceToImage()` before `binding.takeScreenshot('NN-name')`.
