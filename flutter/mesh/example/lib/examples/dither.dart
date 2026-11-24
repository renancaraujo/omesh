import 'package:material_ui/material_ui.dart';
import 'package:mesh/mesh.dart';

class DitherUsage extends StatefulWidget {
  const DitherUsage({super.key});

  static const String code = '''
OMeshGradient(
  // Removes the bands of slow, dark gradients.
  dither: true,
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
  _Sample sample = _Sample.opaque;

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
                ColoredBox(
                  color: _parentColor,
                  child: OMeshGradient(
                    tessellation: 20,
                    mesh: sample.mesh,
                  ),
                ),
                ClipRect(
                  clipper: _RightOf(split),
                  child: ColoredBox(
                    color: _parentColor,
                    child: OMeshGradient(
                      tessellation: 20,
                      dither: true,
                      mesh: sample.mesh,
                    ),
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
      height: 560,
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _Sample.values)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: option == sample,
                    onSelected: (_) => setState(() {
                      sample = option;
                      // Brightening suits the dark opaque mesh only; the
                      // translucent ones would turn white.
                      boost = option == _Sample.opaque;
                    }),
                  ),
              ],
            ),
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
                    'Drag across the image to compare. With dither on, '
                    'colors should look the same; only the bands change.',
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

/// The color under the meshes, so translucent meshes blend over
/// something.
const _parentColor = Color(0xff202020);

/// The meshes to compare with and without dither.
enum _Sample {
  opaque('Opaque, dark'),
  lab('Translucent lab'),
  xyY('Translucent xyY');

  const _Sample(this.label);

  final String label;

  OMeshRect get mesh => switch (this) {
        _Sample.opaque => ditherExampleMesh,
        _Sample.lab => _translucentLab,
        _Sample.xyY => _translucentXyY,
      };
}

/// Half-transparent colors. Mixed in lab or xyY, they give values that
/// dither must leave as they are.
OMeshRect _translucentMesh(OMeshColorSpace colorSpace) => OMeshRect(
      width: 2,
      height: 2,
      colorSpace: colorSpace,
      vertices: [
        (0.0, 0.0).v, (1.0, 0.0).v, // Row 1

        (0.0, 1.0).v, (1.0, 1.0).v, // Row 2
      ],
      colors: const [
        Color(0x80ff0000), Color(0x80ffffff), // Row 1

        Color(0x80ff8000), Color(0x80ffff00), // Row 2
      ],
    );

final OMeshRect _translucentLab = _translucentMesh(OMeshColorSpace.lab);
final OMeshRect _translucentXyY = _translucentMesh(OMeshColorSpace.xyY);

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
