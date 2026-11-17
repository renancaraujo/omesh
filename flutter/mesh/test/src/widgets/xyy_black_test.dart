import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';

void main() {
  testWidgets('xyY blends from black corners', (tester) async {
    await tester.runAsync(OMeshShaderProvider.load);
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox.square(
            dimension: 64,
            child: OMeshGradient(
              mesh: OMeshRect(
                width: 2,
                height: 2,
                colorSpace: OMeshColorSpace.xyY,
                smoothColors: false,
                vertices: [
                  (0.0, 0.0).v, (1.0, 0.0).v, //
                  (0.0, 1.0).v, (1.0, 1.0).v, //
                ],
                colors: const [
                  Color(0xff000000), Color(0xffffffff), //
                  Color(0xff000000), Color(0xffffffff), //
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final pixels = await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData();
      image.dispose();
      return bytes!;
    });

    const center = (32 * 64 + 32) * 4;
    final (r, g, b) = (
      pixels!.getUint8(center),
      pixels.getUint8(center + 1),
      pixels.getUint8(center + 2),
    );
    expect(r, inInclusiveRange(64, 192));
    expect((r - g).abs(), lessThanOrEqualTo(4));
    expect((r - b).abs(), lessThanOrEqualTo(4));
  });
}
