import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';

const _red = Color(0xffff0000);
const _green = Color(0xff00ff00);
const _blue = Color(0xff0000ff);
const _white = Color(0xffffffff);
const _black = Color(0xff000000);
const _yellow = Color(0xffffff00);

OMeshRect _grid(
  int width,
  int height,
  List<Color> colors, {
  double extent = 1,
}) {
  return OMeshRect(
    width: width,
    height: height,
    colorSpace: OMeshColorSpace.linear,
    smoothColors: false,
    vertices: [
      for (var row = 0; row < height; row++)
        for (var col = 0; col < width; col++)
          (col / (width - 1) * extent, row / (height - 1) * extent).v,
    ],
    colors: colors,
  );
}

final OMeshRect _mesh3x3 = _grid(3, 3, const [
  _red, _green, _blue, //
  _white, _black, _yellow, //
  _blue, _red, _green, //
]);

final OMeshRect _mesh2x2 = _grid(2, 2, const [_red, _green, _blue, _white]);

final OMeshRect _bentMesh = OMeshRect(
  width: 2,
  height: 2,
  colorSpace: OMeshColorSpace.linear,
  smoothColors: false,
  vertices: [
    (0.1, 0.1).v.bezier(east: (0.4, 0.6).v, south: (0.5, 0.4).v),
    (0.9, 0.1).v.bezier(west: (0.6, -0.3).v, south: (0.5, 0.5).v),
    (0.1, 0.9).v.bezier(east: (0.4, 0.4).v, north: (0.4, 0.6).v),
    (0.9, 0.9).v.bezier(west: (0.6, 1.2).v, north: (1.2, 0.6).v),
  ],
  colors: const [_red, _green, _blue, _white],
);

class _RecordingCanvas implements Canvas {
  final vertices = <Vertices>[];
  Error? errorOnDraw;

  @override
  void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint) {
    this.vertices.add(vertices);
    if (errorOnDraw case final error?) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<ByteData> _render(
  WidgetTester tester,
  OMeshRectPaint painter,
  Rect rect, {
  Size size = const Size(64, 64),
}) async {
  final recorder = PictureRecorder();
  painter.paint(Canvas(recorder), rect);
  final picture = recorder.endRecording();
  final bytes = await tester.runAsync(() async {
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final bytes = await image.toByteData();
    image.dispose();
    return bytes!;
  });
  picture.dispose();
  return bytes!;
}

(int, int, int) _pixel(ByteData bytes, int x, int y, {int width = 64}) {
  final i = (y * width + x) * 4;
  return (bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2));
}

(int, int, int) _expected(OMeshRect mesh, Rect rect, int x, int y) {
  final u = ((x + 0.5 - rect.left) / rect.width) * (mesh.width - 1);
  final v = ((y + 0.5 - rect.top) / rect.height) * (mesh.height - 1);
  final col = u.floor().clamp(0, mesh.width - 2);
  final row = v.floor().clamp(0, mesh.height - 2);
  final tu = u - col;
  final tv = v - row;
  Color at(int c, int r) => mesh.colors[r * mesh.width + c]!;
  double mix(double Function(Color) channel) {
    final top =
        channel(at(col, row)) * (1 - tu) + channel(at(col + 1, row)) * tu;
    final bottom = channel(at(col, row + 1)) * (1 - tu) +
        channel(at(col + 1, row + 1)) * tu;
    return top * (1 - tv) + bottom * tv;
  }

  return (
    (mix((c) => c.r) * 255).round(),
    (mix((c) => c.g) * 255).round(),
    (mix((c) => c.b) * 255).round(),
  );
}

void _expectMatches(
  ByteData bytes,
  OMeshRect mesh,
  Rect rect, {
  int width = 64,
}) {
  for (var y = rect.top.toInt() + 2; y < rect.bottom - 2; y += 5) {
    for (var x = rect.left.toInt() + 2; x < rect.right - 2; x += 5) {
      final (r, g, b) = _pixel(bytes, x, y, width: width);
      final (er, eg, eb) = _expected(mesh, rect, x, y);
      final reason = 'pixel ($x, $y)';
      expect(r, closeTo(er, 4), reason: reason);
      expect(g, closeTo(eg, 4), reason: reason);
      expect(b, closeTo(eb, 4), reason: reason);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OMeshShaderProvider provider;

  OMeshRectPaint painter(OMeshRect mesh, {int tessellation = 4}) {
    return OMeshRectPaint(
      shaderProvider: provider,
      meshRect: mesh,
      tessellation: tessellation,
      debugMode: null,
    );
  }

  setUpAll(() async {
    provider = await OMeshShaderProvider.load();
  });

  group('tessellation range', () {
    test('clamps to 1..30', () {
      expect(OMeshRectPaint.clampTessellation(-3), 1);
      expect(OMeshRectPaint.clampTessellation(1), 1);
      expect(OMeshRectPaint.clampTessellation(12), 12);
      expect(OMeshRectPaint.clampTessellation(30), 30);
      expect(OMeshRectPaint.clampTessellation(31), 30);
    });

    test('rejects values below 1', () {
      expect(() => painter(_mesh2x2, tessellation: 0), throwsAssertionError);

      final paint = painter(_mesh2x2);
      expect(() => paint.tessellation = 0, throwsAssertionError);
      expect(paint.tessellation, 4);

      expect(
        () => OMeshGradient(mesh: _mesh2x2, tessellation: 0),
        throwsAssertionError,
      );
      expect(
        () => AnimatedOMeshGradient(
          mesh: _mesh2x2,
          duration: Duration.zero,
          tessellation: 0,
        ),
        throwsAssertionError,
      );
    });

    test('warns once for each value above 30', () {
      final messages = <String>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => messages.add(message!);
      addTearDown(() => debugPrint = original);

      painter(_mesh2x2, tessellation: 41)
        ..tessellation = 42
        ..tessellation = 41
        ..tessellation = 42
        ..tessellation = 30;

      expect(messages, hasLength(2));
      expect(messages.first, contains('41'));
      expect(messages.last, contains('42'));
    });

    testWidgets('renders a bent mesh at 40 like 30, unlike 12', (tester) async {
      const rect = Rect.fromLTWH(0, 0, 200, 200);
      Future<List<int>> at(int tessellation) async {
        final bytes = await _render(
          tester,
          painter(_bentMesh, tessellation: tessellation),
          rect,
          size: rect.size,
        );
        return bytes.buffer.asUint8List();
      }

      final max = await at(30);
      expect(await at(40), max);
      expect(await at(12), isNot(max));
    });
  });

  group('draw calls', () {
    test('draws one set of vertices per patch and disposes each', () {
      final canvas = _RecordingCanvas();
      painter(_mesh3x3).paint(canvas, Offset.zero & const Size(64, 64));
      expect(canvas.vertices, hasLength(4));
      expect(canvas.vertices.every((v) => v.debugDisposed), isTrue);
    });

    test('disposes the vertices when drawing throws', () {
      final canvas = _RecordingCanvas()..errorOnDraw = StateError('draw');
      expect(
        () => painter(_mesh3x3).paint(canvas, Offset.zero & const Size(64, 64)),
        throwsStateError,
      );
      expect(canvas.vertices, hasLength(1));
      expect(canvas.vertices.single.debugDisposed, isTrue);
    });
  });

  group('texture grid cache', () {
    const rect = Rect.fromLTWH(0, 0, 64, 64);

    test('is reused while size, rect and tessellation stay the same', () {
      final paint = painter(_mesh3x3)..paint(_RecordingCanvas(), rect);
      expect(paint.debugTextureGridBuilds, 1);

      paint
        ..meshRect = _grid(3, 3, List.filled(9, _red))
        ..paint(_RecordingCanvas(), rect);
      expect(paint.debugTextureGridBuilds, 1);
    });

    test('is rebuilt when the rect changes', () {
      final paint = painter(_mesh3x3)
        ..paint(_RecordingCanvas(), rect)
        ..paint(_RecordingCanvas(), rect.shift(const Offset(3, 0)));
      expect(paint.debugTextureGridBuilds, 2);
    });

    test('is rebuilt when the mesh size changes', () {
      final paint = painter(_mesh3x3)
        ..paint(_RecordingCanvas(), rect)
        ..meshRect = _mesh2x2
        ..paint(_RecordingCanvas(), rect);
      expect(paint.debugTextureGridBuilds, 2);
    });

    test('is rebuilt when the tessellation changes', () {
      final paint = painter(_mesh3x3)
        ..paint(_RecordingCanvas(), rect)
        ..tessellation = 7
        ..paint(_RecordingCanvas(), rect);
      expect(paint.debugTextureGridBuilds, 2);
    });

    test('is not rebuilt between tessellations above 30', () {
      final paint = painter(_mesh3x3, tessellation: 35)
        ..paint(_RecordingCanvas(), rect)
        ..tessellation = 45
        ..paint(_RecordingCanvas(), rect);
      expect(paint.debugTextureGridBuilds, 1);
    });
  });

  group('pixels', () {
    testWidgets('every patch shows its own colors', (tester) async {
      const rect = Rect.fromLTWH(0, 0, 64, 64);
      final bytes = await _render(tester, painter(_mesh3x3), rect);
      _expectMatches(bytes, _mesh3x3, rect);
    });

    testWidgets('a mesh smaller than the rect keeps its colors',
        (tester) async {
      final mesh = _grid(3, 3, _mesh3x3.colors.cast(), extent: 0.5);
      final bytes = await _render(
        tester,
        painter(mesh),
        const Rect.fromLTWH(0, 0, 64, 64),
      );
      _expectMatches(bytes, mesh, const Rect.fromLTWH(0, 0, 32, 32));
    });

    testWidgets('translucent colors are blended once', (tester) async {
      final mesh = _grid(2, 2, List.filled(4, const Color(0x80ff0000)));
      final bytes = await _render(
        tester,
        painter(mesh),
        const Rect.fromLTWH(0, 0, 64, 64),
      );
      for (var y = 2; y < 62; y += 5) {
        for (var x = 2; x < 62; x += 5) {
          final alpha = bytes.getUint8((y * 64 + x) * 4 + 3);
          expect(alpha, closeTo(128, 2), reason: 'pixel ($x, $y)');
        }
      }
    });

    testWidgets('follows the rect on a reused painter', (tester) async {
      final paint = painter(_mesh3x3);
      await _render(tester, paint, const Rect.fromLTWH(0, 0, 64, 64));

      const resized = Rect.fromLTWH(0, 0, 40, 30);
      final bytes = await _render(tester, paint, resized);
      _expectMatches(bytes, _mesh3x3, resized);
    });

    testWidgets('follows the mesh size on a reused painter', (tester) async {
      const rect = Rect.fromLTWH(0, 0, 64, 64);
      final paint = painter(_mesh3x3);
      await _render(tester, paint, rect);

      paint.meshRect = _mesh2x2;
      final bytes = await _render(tester, paint, rect);
      _expectMatches(bytes, _mesh2x2, rect);
    });

    testWidgets('follows the tessellation on a reused painter', (tester) async {
      const rect = Rect.fromLTWH(0, 0, 64, 64);
      final paint = painter(_mesh3x3);
      await _render(tester, paint, rect);

      paint.tessellation = 9;
      final bytes = await _render(tester, paint, rect);
      _expectMatches(bytes, _mesh3x3, rect);
    });
  });
}
