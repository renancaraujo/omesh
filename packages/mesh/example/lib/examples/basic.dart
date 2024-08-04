import 'package:flutter/material.dart';
import 'package:mesh/mesh.dart';

class BasicUsage extends StatelessWidget {
  const BasicUsage({super.key});

  static const String code = '''
    OMeshGradient(
        mesh: OMeshRect(
          width: 3,
          height: 3,
          vertices: [
            (-0.06, -0.08).v,
            (0.58, -0.05).v,
            (1.36, 0.04).v, // Row 1
      
            (-0.02, 0.31).v,
            (0.44, 0.63).v,
            (1.11, 0.4).v, // Row 2
      
            (-0.01, 1.01).v,
            (1.01, 1.0).v,
            (1.02, 0.73).v, // Row 3
          ],
          colors: const [
            Color(0xffa52b68),
            Color(0xff4693a9),
            Color(0xff4693a9), // Row 1
      
            Color(0xffa52ba0),
            Color(0xffe8dad4),
            Color(0xff4693a9), // Row 2
      
            Color(0xff9715a9),
            Color(0xff4693a9),
            Color(0xff4693a9), // Row 3
          ],
        ),
      );
''';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: OMeshGradient(
        tessellation: 30,
        mesh: OMeshRect(
          width: 3,
          height: 3,
          vertices: [
            (-0.06, -0.08).v,
            (0.58, -0.05).v,
            (1.36, 0.04).v, // Row 1

            (-0.02, 0.31).v,
            (0.44, 0.63).v,
            (1.11, 0.4).v, // Row 2

            (-0.01, 1.01).v,
            (1.01, 1.0).v,
            (1.02, 0.73).v, // Row 3
          ],
          colors: const [
            Color(0xffa52b68),
            Color(0xff4693a9),
            Color(0xff4693a9), // Row 1

            Color(0xffa52ba0),
            Color(0xffe8dad4),
            Color(0xff4693a9), // Row 2

            Color(0xff9715a9),
            Color(0xff4693a9),
            Color(0xff4693a9), // Row 3
          ],
        ),
      ),
    );
  }
}
