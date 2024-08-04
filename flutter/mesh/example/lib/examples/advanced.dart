import 'package:flutter/material.dart';
import 'package:mesh/mesh.dart';

class AdvancedUsage extends StatelessWidget {
  const AdvancedUsage({super.key});

  static const String code = '''
    OMeshGradient(
        mesh: OMeshRect(
          width: 5,
          height: 5,
          fallbackColor: const Color(0xffade3fa),
          backgroundColor: const Color(0xffcae3ec),
          vertices: [
            (-0.06, -0.01).v,
            (0.24, -0.07).v,
            (0.51, -0.11).v,
            (0.74, -0.05).v,
            (1.03, -0.02).v, // Row 1

            (-0.04, 0.34).v,
            (0.25, 0.29).v,
            (0.51, 0.17).v,
            (0.75, 0.25).v,
            (1.03, 0.27).v, // Row 2

            (-0.05, 0.44).v,
            (0.15, 0.61).v.bezier(
                  east: (0.25, 0.57).v,
                  west: (0.05, 0.65).v,
                ),
            (0.48, 0.44).v.bezier(
                  east: (0.66, 0.43).v,
                  west: (0.3, 0.47).v,
                ),
            (0.81, 0.51).v.bezier(
                  east: (0.89, 0.51).v,
                  west: (0.68, 0.48).v,
                ),
            (1.03, 0.4).v, // Row 3

            (-0.06, 0.67).v,
            (0.15, 0.65).v.bezier(
                  east: (0.25, 0.61).v,
                  west: (0.07, 0.68).v,
                ),
            (0.48, 0.54).v.bezier(
                  east: (0.69, 0.55).v,
                  west: (0.28, 0.56).v,
                ),
            (0.92, 0.67).v.bezier(
                  north: (0.92, 0.6).v,
                ),
            (1.03, 0.7).v, // Row 4

            (-0.03, 1.04).v,
            (0.35, 1.02).v,
            (0.65, 1.06).v,
            (0.93, 1.02).v,
            (1.07, 1.03).v, // Row 5
          ],
          colors: const [
            null,
            null,
            null,
            null,
            null, // Row 1

            Color(0xffeef8ff),
            Color(0xffd5ebff),
            Color(0xffedf5ff),
            Color(0xffedf5ff),
            Color(0xffedf5ff), // Row 2

            Color(0x73efe8ff),
            Color(0x73efe8ff),
            Color(0x54efe8ff),
            Color(0x73efe8ff),
            Color(0x73efe8ff), // Row 3

            Color(0xff003e48),
            Color(0xff00495b),
            Color(0xff004e5b),
            Color(0xff004e5b),
            Color(0xff004e5b), // Row 4

            Color(0xf7010c0c),
            Color(0xf7011515),
            Color(0xf7011e1e),
            Color(0xf7013131),
            Color(0xff025352), // Row 5
          ],
        ),
      );
''';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: OMeshGradient(
        mesh: OMeshRect(
          width: 5,
          height: 5,
          fallbackColor: const Color(0xffade3fa),
          backgroundColor: const Color(0xffcae3ec),
          vertices: [
            (-0.06, -0.01).v,
            (0.24, -0.07).v,
            (0.51, -0.11).v,
            (0.74, -0.05).v,
            (1.03, -0.02).v, // Row 1

            (-0.04, 0.34).v,
            (0.25, 0.29).v,
            (0.51, 0.17).v,
            (0.75, 0.25).v,
            (1.03, 0.27).v, // Row 2

            (-0.05, 0.44).v,
            (0.15, 0.61).v.bezier(
                  east: (0.25, 0.57).v,
                  west: (0.05, 0.65).v,
                ),
            (0.48, 0.44).v.bezier(
                  east: (0.66, 0.43).v,
                  west: (0.3, 0.47).v,
                ),
            (0.81, 0.51).v.bezier(
                  east: (0.89, 0.51).v,
                  west: (0.68, 0.48).v,
                ),
            (1.03, 0.4).v, // Row 3

            (-0.06, 0.67).v,
            (0.15, 0.65).v.bezier(
                  east: (0.25, 0.61).v,
                  west: (0.07, 0.68).v,
                ),
            (0.48, 0.54).v.bezier(
                  east: (0.69, 0.55).v,
                  west: (0.28, 0.56).v,
                ),
            (0.92, 0.67).v.bezier(
                  north: (0.92, 0.6).v,
                ),
            (1.03, 0.7).v, // Row 4

            (-0.03, 1.04).v,
            (0.35, 1.02).v,
            (0.65, 1.06).v,
            (0.93, 1.02).v,
            (1.07, 1.03).v, // Row 5
          ],
          colors: const [
            null,
            null,
            null,
            null,
            null, // Row 1

            Color(0xffeef8ff),
            Color(0xffd5ebff),
            Color(0xffedf5ff),
            Color(0xffedf5ff),
            Color(0xffedf5ff), // Row 2

            Color(0x73efe8ff),
            Color(0x73efe8ff),
            Color(0x54efe8ff),
            Color(0x73efe8ff),
            Color(0x73efe8ff), // Row 3

            Color(0xff003e48),
            Color(0xff00495b),
            Color(0xff004e5b),
            Color(0xff004e5b),
            Color(0xff004e5b), // Row 4

            Color(0xf7010c0c),
            Color(0xf7011515),
            Color(0xf7011e1e),
            Color(0xf7013131),
            Color(0xff025352), // Row 5
          ],
        ),
      ),
    );
  }
}
