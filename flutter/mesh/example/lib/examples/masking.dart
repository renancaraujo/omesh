import 'package:flutter/material.dart';
import 'package:mesh/mesh.dart';
import 'package:mix/mix.dart';
import 'package:widget_mask/widget_mask.dart';

class MaskingUsage extends StatelessWidget {
  const MaskingUsage({super.key});

  static const String code = '''
    WidgetMask(
      blendMode: BlendMode.dstATop,
      mask: Center(child: Text('Mesh Gradient')), // your mask
      child: OMeshGradient(
        addRepaintBoundary: false, // set this to false
        ...
      )
    )
''';

  @override
  Widget build(BuildContext context) {
    return WidgetMask(
      blendMode: BlendMode.dstATop,
      mask: Center(
        child: Box(
          style: Style(
            $box.padding(0, 10, 30),
            $text.textAlign(TextAlign.center),
            $text.style(
              color: Colors.white,
              fontSize: 84,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const StyledText('Mesh\nGradient'),
        ),
      ),
      child: SizedBox(
        height: 500,
        child: OMeshGradient(
          tessellation: 30,
          addRepaintBoundary: false,
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
      ),
    );
  }
}
