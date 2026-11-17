import 'package:flutter/material.dart';
import 'package:mesh/mesh.dart';

class DitherUsage extends StatefulWidget {
  const DitherUsage({super.key});

  static const String code = '''
OMeshGradient(
  // Removes the bands of slow, dark gradients.
  dither: true,
  mesh: OMeshRect(
    width: 3,
    height: 3,
    vertices: [
      (0.0, 0.0).v, (0.5, 0.0).v, (1.0, 0.0).v, // Row 1

      (0.0, 0.5).v, (0.62, 0.46).v, (1.0, 0.5).v, // Row 2

      (0.0, 1.0).v, (0.5, 1.0).v, (1.0, 1.0).v, // Row 3
    ],
    colors: const [
      Color(0xff07080f), Color(0xff0c0b1c), Color(0xff07080f), // Row 1

      Color(0xff120d26), Color(0xff2b1a45), Color(0xff160f2c), // Row 2

      Color(0xff07080f), Color(0xff0f0b20), Color(0xff07080f), // Row 3
    ],
  ),
);
''';

  @override
  State<DitherUsage> createState() => _DitherUsageState();
}

class _DitherUsageState extends State<DitherUsage> {
  bool dither = false;
  bool boost = true;

  @override
  Widget build(BuildContext context) {
    final gradient = OMeshGradient(
      tessellation: 30,
      dither: dither,
      mesh: ditherExampleMesh,
    );

    return SizedBox(
      height: 500,
      child: Column(
        children: [
          Expanded(
            child: boost
                ? ColorFiltered(
                    colorFilter: const ColorFilter.matrix(_boost4x),
                    child: gradient,
                  )
                : gradient,
          ),
          _Toggle(
            label: 'dither',
            value: dither,
            onChanged: (value) => setState(() => dither = value),
          ),
          _Toggle(
            label: 'Brighten 4× to show the bands (not part of the API)',
            value: boost,
            onChanged: (value) => setState(() => boost = value),
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

/// A dark, opaque mesh with slow color changes: the case where 8-bit
/// colors show bands.
final ditherExampleMesh = OMeshRect(
  width: 3,
  height: 3,
  vertices: [
    (0.0, 0.0).v, (0.5, 0.0).v, (1.0, 0.0).v, // Row 1

    (0.0, 0.5).v, (0.62, 0.46).v, (1.0, 0.5).v, // Row 2

    (0.0, 1.0).v, (0.5, 1.0).v, (1.0, 1.0).v, // Row 3
  ],
  colors: const [
    Color(0xff07080f), Color(0xff0c0b1c), Color(0xff07080f), // Row 1

    Color(0xff120d26), Color(0xff2b1a45), Color(0xff160f2c), // Row 2

    Color(0xff07080f), Color(0xff0f0b20), Color(0xff07080f), // Row 3
  ],
);

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Switch(value: value, onChanged: onChanged),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
