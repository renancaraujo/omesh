import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';

// Each test file runs in its own isolate, so the grain shader starts
// unloaded here. The tests run in order and share that state.

final OMeshRect _grey = OMeshRect(
  width: 2,
  height: 2,
  colorSpace: OMeshColorSpace.linear,
  vertices: [
    (0.0, 0.0).v, (1.0, 0.0).v, //
    (0.0, 1.0).v, (1.0, 1.0).v, //
  ],
  colors: const [
    Color(0xff808080), Color(0xff808080), //
    Color(0xff808080), Color(0xff808080), //
  ],
);

final GlobalKey _boundaryKey = GlobalKey();

Future<double> _redNoise(WidgetTester tester) async {
  final boundary =
      _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    image.dispose();
    return data!.buffer.asUint8List();
  });
  final reds = [for (var i = 0; i < bytes!.length; i += 4) bytes[i] - 0x80];
  final mean = reds.reduce((a, b) => a + b) / reds.length;
  final variance =
      reds.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
          reds.length;
  return math.sqrt(variance);
}

Widget _gradient(OMeshGrain? grain) => Center(
      child: RepaintBoundary(
        key: _boundaryKey,
        child: SizedBox.square(
          dimension: 32,
          // Dither off, so the noise measured is grain alone.
          child: OMeshGradient(mesh: _grey, grain: grain, dither: false),
        ),
      ),
    );

void main() {
  testWidgets('a gradient without grain does not load the grain shader',
      (tester) async {
    final provider = (await tester.runAsync(OMeshShaderProvider.load))!;
    addTearDown(provider.dispose);

    await tester.pumpWidget(_gradient(null));
    await tester.pumpWidget(_gradient(OMeshGrain.none));
    await tester.pumpWidget(_gradient(const OMeshGrain(amount: 0)));

    expect(OMeshShaderProvider.debugGrainShaderLoadStarted, isFalse);
  });

  testWidgets('a gradient loads the grain shader for visible grain',
      (tester) async {
    const grain = OMeshGrain(amount: 0.1, scatter: 0, shadows: 1);
    await tester.pumpWidget(_gradient(grain));
    expect(OMeshShaderProvider.debugGrainShaderLoadStarted, isTrue);

    // Drawn without grain until the shader has loaded.
    expect(await _redNoise(tester), 0);

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(await _redNoise(tester), greaterThan(5));
  });
}
