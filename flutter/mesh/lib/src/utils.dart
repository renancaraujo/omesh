import 'package:mesh/mesh.dart';
import 'dart:ui' as ui;
// import 'package:vector_math/vector_math.dart' as vm;

/// Linearly interpolates between two [vm.Vector2] objects.
// vm.Vector2 vector2Lerp(vm.Vector2 a, vm.Vector2 b, double t) {
//   return a.lerp(b, t);
// }

/// Linearly interpolates between two [vm.Vector2] objects.
ui.Offset? vector2MaybeLerp(ui.Offset? a, ui.Offset? b, double t) {
  if (a == null && b == null) {
    return null;
  }
  if (a == null) {
    return b;
  }

  if (b == null) {
    return a;
  }

  return ui.Offset.lerp(a, b, t);
}
