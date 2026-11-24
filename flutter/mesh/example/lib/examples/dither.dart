import 'package:material_ui/material_ui.dart';
import 'package:mesh/mesh.dart';

class DitherUsage extends StatefulWidget {
  const DitherUsage({super.key});

  static const String code = '''
OMeshGradient(
  // Dither is on by default and removes the bands of slow, dark
  // gradients. Set it to false to turn it off.
  dither: false,
  mesh: OMeshRect(
    width: 2,
    height: 2,
    vertices: [
      (0.0, 0.0).v, (1.0, 0.0).v, // Row 1

      (0.0, 1.0).v, (1.0, 1.0).v, // Row 2
    ],
    colors: const [
      Color(0xff16141f), Color(0xff1f1a2e), // Row 1

      Color(0xff1a1730), Color(0xff2a1f3a), // Row 2
    ],
  ),
);
''';

  @override
  State<DitherUsage> createState() => _DitherUsageState();
}

class _DitherUsageState extends State<DitherUsage> {
  /// Where the split between the two halves is, from 0 (left) to 1 (right).
  double split = 0.5;
  bool boost = true;

  @override
  Widget build(BuildContext context) {
    final comparison = LayoutBuilder(
      builder: (context, constraints) {
        void moveSplit(Offset position) {
          setState(() {
            split = (position.dx / constraints.maxWidth).clamp(0.0, 1.0);
          });
        }

        return GestureDetector(
          onTapDown: (details) => moveSplit(details.localPosition),
          onHorizontalDragUpdate: (details) => moveSplit(details.localPosition),
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: Stack(
              fit: StackFit.expand,
              children: [
                OMeshGradient(
                  tessellation: 20,
                  dither: false,
                  mesh: ditherExampleMesh,
                ),
                ClipRect(
                  clipper: _RightOf(split),
                  child: OMeshGradient(
                    tessellation: 20,
                    mesh: ditherExampleMesh,
                  ),
                ),
                Align(
                  alignment: Alignment(split * 2 - 1, 0),
                  child: Container(width: 2, color: Colors.white),
                ),
                const Positioned(
                  left: 12,
                  top: 12,
                  child: _Label('dither: false'),
                ),
                const Positioned(
                  right: 12,
                  top: 12,
                  child: _Label('dither: true'),
                ),
              ],
            ),
          ),
        );
      },
    );

    return SizedBox(
      height: 500,
      child: Column(
        children: [
          Expanded(
            child: boost
                ? ColorFiltered(
                    colorFilter: const ColorFilter.matrix(_boost4x),
                    child: comparison,
                  )
                : comparison,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Switch(
                  value: boost,
                  onChanged: (value) => setState(() => boost = value),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Brighten 4× to show the bands (not part of the API). '
                    'Drag across the image to compare.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Multiplies red, green and blue by 4, so steps of one color level
/// become steps of four and the bands are easy to see.
const _boost4x = <double>[
  4, 0, 0, 0, 0, //
  0, 4, 0, 0, 0, //
  0, 0, 4, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// A dark, fully opaque mesh with slow color changes: the case where
/// 8-bit colors show bands.
final ditherExampleMesh = OMeshRect(
  width: 2,
  height: 2,
  vertices: [
    (0.0, 0.0).v, (1.0, 0.0).v, // Row 1

    (0.0, 1.0).v, (1.0, 1.0).v, // Row 2
  ],
  colors: const [
    Color(0xff16141f), Color(0xff1f1a2e), // Row 1

    Color(0xff1a1730), Color(0xff2a1f3a), // Row 2
  ],
);

/// Clips to the part of the box right of [fraction] of its width.
class _RightOf extends CustomClipper<Rect> {
  const _RightOf(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(size.width * fraction, 0, size.width, size.height);

  @override
  bool shouldReclip(_RightOf oldClipper) => oldClipper.fraction != fraction;
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}
