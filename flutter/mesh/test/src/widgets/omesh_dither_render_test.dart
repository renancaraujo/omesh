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

Future<Uint8List> _render(WidgetTester tester, {required bool dither}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: OMeshGradient(mesh: _darkMesh, size: _size, dither: dither),
        ),
      ),
    ),
  );
  // Let the shader program load on the first run.
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

void main() {
  group('$OMeshGradient dither', () {
    testWidgets('changes pixels by at most one step', (t) async {
      final plain = await _render(t, dither: false);
      final dithered = await _render(t, dither: true);
      expect(plain.length, dithered.length);
      var differing = 0;
      for (var i = 0; i < plain.length; i++) {
        if (plain[i] != dithered[i]) differing++;
        expect((plain[i] - dithered[i]).abs(), lessThanOrEqualTo(2));
      }
      expect(differing, greaterThan(0));
    });
  });
}
