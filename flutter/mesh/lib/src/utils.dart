import 'package:mesh/mesh.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Linearly interpolates between two [vm.Vector2] objects.
vm.Vector2 vector2Lerp(vm.Vector2 a, vm.Vector2 b, double t) {
  return a.lerp(b, t);
}

/// Linearly interpolates between two [vm.Vector2] objects.
vm.Vector2? vector2MaybeLerp(vm.Vector2? a, vm.Vector2? b, double t) {
  if (a == null && b == null) {
    return null;
  }
  if (a == null) {
    return b;
  }

  if (b == null) {
    return a;
  }

  return a.lerp(b, t);
}

extension on vm.Vector2 {
  vm.Vector2 lerp(vm.Vector2 to, double t) {
    return OVertex.zero()
      ..setFrom(to)
      ..sub(this)
      ..scale(t)
      ..add(this);
  }
}
