import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';

/// Dark, translucent mesh over an opaque background: the banding case.
final _darkMesh = OMeshRect(
  width: 2,
  height: 2,
  backgroundColor: const Color(0xff171721),
  vertices: [
    (0.0, 0.0).v, (1.0, 0.0).v, //
    (0.0, 1.0).v, (1.0, 1.0).v, //
  ],
  colors: const [
    Color(0x12171721), Color(0x34f84f39), //
    Color(0x388f89fa), Color(0x34f985e1), //
  ],
);

const _size = Size(120, 120);

Future<Uint8List> _render(WidgetTester tester, OMeshGrain? grain) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: OMeshGradient(mesh: _darkMesh, size: _size, grain: grain),
        ),
      ),
    ),
  );
  // Let the shader programs load on the first run.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();

  final bytes = await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData();
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

int _differingBytes(Uint8List a, Uint8List b) {
  expect(a.length, b.length);
  var count = 0;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) count++;
  }
  return count;
}

void main() {
  group('$OMeshGradient grain', () {
    testWidgets('OMeshGrain.none renders exactly like no grain', (t) async {
      final plain = await _render(t, null);
      final none = await _render(t, OMeshGrain.none);
      expect(_differingBytes(plain, none), 0);
    });

    testWidgets('dither changes pixels by at most one step', (t) async {
      final plain = await _render(t, null);
      final dithered = await _render(t, OMeshGrain.ditherOnly);
      expect(_differingBytes(plain, dithered), greaterThan(0));
      for (var i = 0; i < plain.length; i++) {
        expect((plain[i] - dithered[i]).abs(), lessThanOrEqualTo(2));
      }
    });

    testWidgets('scatter and visible grain change the image', (t) async {
      final plain = await _render(t, null);
      final scattered = await _render(
        t,
        const OMeshGrain(amount: 0, scatter: 12, dither: false),
      );
      final grainy = await _render(
        t,
        const OMeshGrain(amount: 0.2, scatter: 0, dither: false),
      );
      expect(_differingBytes(plain, scattered), greaterThan(0));
      expect(_differingBytes(plain, grainy), greaterThan(0));
    });

    testWidgets('the default grain paints without errors', (t) async {
      await _render(t, const OMeshGrain());
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('OMeshRectPaint.dispose works without painting', (t) async {
    final provider = (await t.runAsync(OMeshShaderProvider.load))!;
    OMeshRectPaint(
      shaderProvider: provider,
      meshRect: _darkMesh,
      tessellation: 4,
      debugMode: null,
      grain: const OMeshGrain(),
      devicePixelRatio: 2,
    ).dispose();
    provider.dispose();
  });
}
