import 'package:flutter/material.dart';
import 'package:mesh/mesh.dart';

class GrainUsage extends StatefulWidget {
  const GrainUsage({super.key});

  static const String code = '''
OMeshGradient(
  grain: const OMeshGrain(
    // Visible grain, weighted by brightness. 0 turns it off.
    amount: 0.05,
    // Random offset of each pixel's color lookup, in logical
    // pixels. 0 turns it off.
    scatter: 12,
  ),
  mesh: OMeshRect(
    width: 3,
    height: 3,
    colorSpace: OMeshColorSpace.lab,
    vertices: [
      (0.0, 0.0).v, (0.5, 0.0).v, (1.0, 0.0).v, // Row 1

      (0.0, 0.55).v,
      (0.45, 0.5).v.bezier(
        east: (0.75, 0.38).v,
        west: (0.2, 0.62).v,
      ),
      (1.0, 0.45).v, // Row 2

      (0.0, 1.0).v, (0.5, 1.0).v, (1.0, 1.0).v, // Row 3
    ],
    colors: const [
      Color(0xff0a0a14), Color(0xff1a1030), Color(0xff0a0a14), // Row 1

      Color(0xff3a1846), Color(0xffff7a4d), Color(0xff5a1f5e), // Row 2

      Color(0xff0a0a14), Color(0xff2a1238), Color(0xff0a0a14), // Row 3
    ],
  ),
);
''';

  @override
  State<GrainUsage> createState() => _GrainUsageState();
}

class _GrainUsageState extends State<GrainUsage> {
  double amount = 0.05;
  double scatter = 12;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Column(
        children: [
          Expanded(
            child: OMeshGradient(
              tessellation: 30,
              grain: OMeshGrain(amount: amount, scatter: scatter),
              mesh: grainExampleMesh,
            ),
          ),
          _SliderRow(
            label: 'amount',
            value: amount,
            max: 0.3,
            format: (value) => value.toStringAsFixed(2),
            onChanged: (value) => setState(() => amount = value),
          ),
          _SliderRow(
            label: 'scatter',
            value: scatter,
            max: 40,
            format: (value) => '${value.round()} px',
            onChanged: (value) => setState(() => scatter = value),
          ),
        ],
      ),
    );
  }
}

/// A dark mesh with a warm glow in the middle.
final grainExampleMesh = OMeshRect(
  width: 3,
  height: 3,
  colorSpace: OMeshColorSpace.lab,
  vertices: [
    (0.0, 0.0).v, (0.5, 0.0).v, (1.0, 0.0).v, // Row 1

    (0.0, 0.55).v,
    (0.45, 0.5).v.bezier(
          east: (0.75, 0.38).v,
          west: (0.2, 0.62).v,
        ),
    (1.0, 0.45).v, // Row 2

    (0.0, 1.0).v, (0.5, 1.0).v, (1.0, 1.0).v, // Row 3
  ],
  colors: const [
    Color(0xff0a0a14), Color(0xff1a1030), Color(0xff0a0a14), // Row 1

    Color(0xff3a1846), Color(0xffff7a4d), Color(0xff5a1f5e), // Row 2

    Color(0xff0a0a14), Color(0xff2a1238), Color(0xff0a0a14), // Row 3
  ],
);

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.max,
    required this.format,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final String Function(double value) format;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Colors.white, fontSize: 14);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: style)),
          Expanded(
            child: Slider(value: value, max: max, onChanged: onChanged),
          ),
          SizedBox(
            width: 60,
            child: Text(format(value), style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
