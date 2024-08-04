import 'package:flutter/material.dart';
import 'package:mesh/mesh.dart';

class InstrinsicAnimation extends StatefulWidget {
  const InstrinsicAnimation({super.key});

  static const String code = """

class MyWidget extends StatefulWidget {
...
}
....
class _MyWidgetState extends State<MyWidget> {
  bool distorted = false;

  @override
  Widget build(BuildContext context) {
    final middle = distorted ? 0.57 : 0.33;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOMeshGradient(
            size: const Size(400, 400),
            curve: Curves.easeInOut,
            tessellation: 14,
            duration: const Duration(seconds: 1),
            mesh: OMeshRect(
              width: 3,
              height: 4,
              colorSpace: OMeshColorSpace.linear,
              vertices: [
                (0.0, 0.0).v, (0.5, 0.0).v, (1.0, 0.0).v, //

                (0.0, 0.33).v,
                (middle, middle).v.bezier(
                      east: (middle + (0.9 - middle), middle).v,
                      west: (middle - (middle - 0.1), middle).v,
                    ),
                (1.0, 0.33).v, //

                (0.0, 0.66).v,
                (middle, 0.66).v.bezier(),
                (1.0, 0.66).v, //

                (0.0, 1.0).v, (0.5, 1.0).v, (1.0, 1.0).v, //
              ],
              colors: const [
                Colors.red, Colors.green, Colors.blue, //
                Colors.yellow, Colors.purple, Colors.orange, //
                Colors.teal, Colors.green, Colors.pink, //
                Colors.cyan, Colors.pinkAccent, Colors.amber, //
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                distorted = !distorted;
              });
            },
            child: Text(distorted ? 'Reset' : 'Distort'),
          ),
        ],
      ),
    );
  }
}

""";

  @override
  State<InstrinsicAnimation> createState() => _InstrinsicAnimationState();
}

class _InstrinsicAnimationState extends State<InstrinsicAnimation> {
  bool distorted = false;

  @override
  Widget build(BuildContext context) {
    final middle = distorted ? 0.57 : 0.33;

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOMeshGradient(
            size: const Size(400, 400),
            curve: Curves.easeInOut,
            debugMode: DebugMode.none,
            tessellation: 12,
            impellerCompatibilityMode: true,
            duration: const Duration(seconds: 1),
            mesh: OMeshRect(
              width: 3,
              height: 4,
              colorSpace: OMeshColorSpace.linear,
              vertices: [
                (0.0, 0.0).v, (0.5, 0.0).v, (1.0, 0.0).v, //

                (0.0, 0.33).v,
                (middle, middle).v.bezier(
                      east: (middle + (0.9 - middle), middle).v,
                      west: (middle - (middle - 0.1), middle).v,
                    ),
                (1.0, 0.33).v, //

                (0.0, 0.66).v,
                (middle, 0.66).v.bezier(),
                (1.0, 0.66).v, //

                (0.0, 1.0).v, (0.5, 1.0).v, (1.0, 1.0).v, //
              ],
              colors: const [
                Colors.red, Colors.green, Colors.blue, //
                Colors.yellow, Colors.purple, Colors.orange, //
                Colors.teal, Colors.green, Colors.pink, //
                Colors.cyan, Colors.pinkAccent, Colors.amber, //
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                distorted = !distorted;
              });
            },
            child: Text(distorted ? 'Reset' : 'Distort'),
          ),
        ],
      ),
    );
  }
}
