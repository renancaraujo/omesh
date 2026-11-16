import 'package:flutter/widgets.dart';
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

final OMeshRect _otherMesh =
    _mesh.setColor(const Color(0xff00ffff), onIndex: 3);

Widget _gradient() => OMeshGradient(mesh: _mesh, size: const Size(100, 100));

Widget _animated(OMeshRect mesh) => AnimatedOMeshGradient(
      mesh: mesh,
      duration: const Duration(seconds: 1),
      size: const Size(100, 100),
    );

Finder get _animatedPaint => find.descendant(
      of: find.byType(AnimatedOMeshGradient),
      matching: find.byType(CustomPaint),
    );

Finder get _meshPaint => find.descendant(
      of: find.byType(OMeshGradient),
      matching: find.byType(CustomPaint),
    );

PageRoute<T> _route<T>(WidgetBuilder builder, {RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  );
}

Widget _app({
  required Widget home,
  GlobalKey<NavigatorState>? navigatorKey,
  List<NavigatorObserver> navigatorObservers = const [],
}) {
  return WidgetsApp(
    color: const Color(0xff000000),
    navigatorKey: navigatorKey,
    navigatorObservers: navigatorObservers,
    pageRouteBuilder: <T>(settings, builder) {
      return _route<T>(builder, settings: settings);
    },
    home: home,
  );
}

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
        await tester.pumpWidget(_app(home: _gradient()));
        await tester.pump();
        expect(_meshPaint, findsOneWidget);

        await tester.pumpWidget(_app(home: Center(child: _gradient())));

        expect(find.byType(OMeshGradient), findsOneWidget);
        expect(_meshPaint, findsOneWidget);
      },
    );

    testWidgets('does not flash during a hero flight', (tester) async {
      const tag = 'mesh';
      final navigatorKey = GlobalKey<NavigatorState>();
      final heroController = HeroController();
      addTearDown(heroController.dispose);

      await tester.pumpWidget(
        _app(
          navigatorKey: navigatorKey,
          navigatorObservers: [heroController],
          home: Hero(tag: tag, child: _gradient()),
        ),
      );
      await tester.pump();
      expect(_meshPaint, findsOneWidget);

      navigatorKey.currentState!.push(
        _route<void>(
          (_) => Center(child: Hero(tag: tag, child: _gradient())),
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

  group('$AnimatedOMeshGradient', () {
    testWidgets('does not animate on the first build', (tester) async {
      await tester.pumpWidget(_animated(_mesh));
      await tester.pump();

      expect(_animatedPaint, findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('repaints on every tick without rebuilding', (tester) async {
      await tester.pumpWidget(_animated(_mesh));
      await tester.pump();
      await tester.pumpWidget(_animated(_otherMesh));

      final painter = tester.widget<CustomPaint>(_animatedPaint).painter!;
      var repaints = 0;
      void onRepaint() => repaints++;
      painter.addListener(onRepaint);

      for (var frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester.widget<CustomPaint>(_animatedPaint).painter,
          same(painter),
          reason: 'the widget should not rebuild while animating',
        );
      }
      expect(repaints, 5);

      painter.removeListener(onRepaint);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('restarts from the current value when the mesh changes',
        (tester) async {
      await tester.pumpWidget(_animated(_mesh));
      await tester.pump();
      await tester.pumpWidget(_animated(_otherMesh));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.pumpWidget(_animated(_mesh));
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
