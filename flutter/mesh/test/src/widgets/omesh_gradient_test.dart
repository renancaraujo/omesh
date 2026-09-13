import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';

final _mesh = OMeshRect(
  width: 2,
  height: 2,
  vertices: [
    (0.0, 0.0).v, (1.0, 0.0).v, //
    (0.0, 1.0).v, (1.0, 1.0).v, //
  ],
  colors: const [
    Color(0xffff0000), Color(0xff00ff00), //
    Color(0xff0000ff), Color(0xffffff00), //
  ],
);

Widget _gradient() => OMeshGradient(mesh: _mesh, size: const Size(100, 100));

Finder get _meshPaint => find.descendant(
      of: find.byType(OMeshGradient),
      matching: find.byType(CustomPaint),
    );

void _expectAllMeshesPainted({required String reason}) {
  final meshes = find.byType(OMeshGradient).evaluate().length;
  expect(meshes, greaterThan(0), reason: reason);
  expect(_meshPaint, findsNWidgets(meshes), reason: reason);
}

void main() {
  group('$OMeshGradient', () {
    testWidgets(
      'paints on the first frame once the shader program is cached',
      (tester) async {
        await tester.pumpWidget(MaterialApp(home: _gradient()));
        await tester.pump();
        expect(_meshPaint, findsOneWidget);

        await tester.pumpWidget(MaterialApp(home: Center(child: _gradient())));

        expect(find.byType(OMeshGradient), findsOneWidget);
        expect(_meshPaint, findsOneWidget);
      },
    );

    testWidgets('does not flash during a hero flight', (tester) async {
      const tag = 'mesh';
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Hero(tag: tag, child: _gradient()),
        ),
      );
      await tester.pump();
      expect(_meshPaint, findsOneWidget);

      unawaited(
        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => Center(child: Hero(tag: tag, child: _gradient())),
          ),
        ),
      );

      await tester.pump();

      await tester.pump();
      expect(find.byType(OMeshGradient), findsOneWidget);
      expect(_meshPaint, findsOneWidget, reason: 'shuttle should be painted');

      final destinationMesh = find.descendant(
        of: find.byType(Hero),
        matching: find.byType(OMeshGradient),
      );
      var frame = 2;
      while (destinationMesh.evaluate().isEmpty) {
        expect(frame, lessThan(200), reason: 'flight should have ended');
        await tester.pump(const Duration(milliseconds: 16));
        frame++;
        _expectAllMeshesPainted(reason: 'frame $frame should be painted');
      }
      expect(_meshPaint, findsOneWidget, reason: 'destination painted');

      await tester.pumpAndSettle();
      expect(_meshPaint, findsOneWidget);
    });
  });
}
