import 'package:flutter/rendering.dart' show Offset;
import 'package:mesh/mesh.dart';
import 'package:mesh/src/utils.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// A vertex with bezier control points.
///
/// It extends [vm.Vector2] and adds control points for each direction on
/// a [OMeshRect].
///
/// The control points are used to create bezier curves between vertices.
///
/// The widget will infet the position of the control points if they are not
/// provided.
///
/// Use shorthand initializers to create a new [OVertex] via one of the
/// following extensions:
/// - `(0.0, 0.0).v`
///   => `OVertex(0.0, 0.0)`
/// - `(0, 0).v`
///   => `OVertex(0.0, 0.0)`
/// - `(0.5, 0.5).v.bezier(north: (0.5, 0.4).v)`
///   => `OVertex.bezier(position: OVertex(0.5, 0.5), north: OVertex(0.5, 0.5))`
///
/// It is also possible to convert an [Offset] or a [vm.Vector2] to an [OVertex]
/// via the following extensions:
/// - `Offset(0.0, 0.0).toOVertex()`
/// - `Vector2(0.0, 0.0).toOVertex()`
class OVertex extends vm.Vector2 {
  /// Creates a new [OVertex] with the given [x] and [y] values.
  factory OVertex(double x, double y) {
    return OVertex.zero()..setValues(x, y);
  }

  /// Creates a new zeroed and empty [OVertex].
  OVertex.zero()
      : northCp = null,
        eastCp = null,
        southCp = null,
        westCp = null,
        super.zero();

  /// Creates a new [OVertex] from a [vm.Vector2].
  factory OVertex.vector2(vm.Vector2 vector2) {
    return OVertex.zero()..setFrom(vector2);
  }

  /// Creates a new [OVertex] from an [Offset].
  factory OVertex.offset(Offset offset) {
    return OVertex.zero()..setValues(offset.dx, offset.dy);
  }

  /// Creates a new [OVertex] with the same [x] and [y] values.
  factory OVertex.all(double xy) {
    return OVertex.zero()..setValues(xy, xy);
  }

  /// Creates a copy of the given [OVertex].
  factory OVertex.copy(OVertex other) {
    return OVertex.zero()
      ..setFrom(other)
      ..northCp = other.northCp
      ..eastCp = other.eastCp
      ..southCp = other.southCp
      ..westCp = other.westCp;
  }

  /// Linearly interpolates between two [OVertex] objects.
  factory OVertex.lerp(OVertex a, OVertex b, double t) {
    final n = vector2MaybeLerp(a.northCp, b.northCp, t);
    final e = vector2MaybeLerp(a.eastCp, b.eastCp, t);
    final s = vector2MaybeLerp(a.southCp, b.southCp, t);
    final w = vector2MaybeLerp(a.westCp, b.westCp, t);

    return a._lerp(b, t)
      ..northCp = n
      ..eastCp = e
      ..southCp = s
      ..westCp = w;
  }

  /// Creates a new [OVertex] with bezier control points.
  factory OVertex.bezier({
    required OVertex position,
    vm.Vector2? north,
    vm.Vector2? east,
    vm.Vector2? south,
    vm.Vector2? west,
  }) {
    return OVertex.zero()
      ..setFrom(position)
      ..northCp = north
      ..eastCp = east
      ..southCp = south
      ..westCp = west;
  }

  /// The bezier control point for the north direction.
  vm.Vector2? northCp;

  /// The bezier control point for the east direction.
  vm.Vector2? eastCp;

  /// The bezier control point for the south direction.
  vm.Vector2? southCp;

  /// The bezier control point for the west direction.
  vm.Vector2? westCp;

  OVertex _lerp(OVertex to, double t) {
    return OVertex.zero()
      ..setFrom(to)
      ..sub(this)
      ..scale(t)
      ..add(this);
  }

  @override
  OVertex clone() => OVertex.copy(this);

  /// Converts this [OVertex] to an [Offset].
  Offset toOffset() => Offset(x, y);

  @override
  OVertex operator -() => clone()..negate();

  @override
  OVertex operator +(vm.Vector2 other) => clone()..add(other);

  @override
  OVertex operator -(vm.Vector2 other) => clone()..sub(other);

  @override
  OVertex operator *(double scale) => clone()..scale(scale);

  /// Check if two vectors are the same.
  @override
  bool operator ==(Object other) =>
      other is OVertex &&
      x == other.x &&
      y == other.y &&
      northCp == other.northCp &&
      eastCp == other.eastCp &&
      southCp == other.southCp &&
      westCp == other.westCp;

  @override
  int get hashCode => Object.hash(x, y, northCp, eastCp, southCp, westCp);
}

/// Extension on [vm.Vector2] to convert it to an [OVertex].
extension Vector2ToOVertex on vm.Vector2 {
  /// Converts a [vm.Vector2] to an [OVertex] with
  /// the given control points.
  OVertex toOVertex({
    vm.Vector2? northCp,
    vm.Vector2? eastCp,
    vm.Vector2? southCp,
    vm.Vector2? westCp,
  }) =>
      OVertex.vector2(this)
        ..northCp = northCp
        ..eastCp = eastCp
        ..southCp = southCp
        ..westCp = westCp;
}

/// Extension on [Offset] to convert it to an [OVertex].
extension OffsetToOVertex on Offset {
  /// Converts an [Offset] to an [OVertex] with
  /// the given control points.
  OVertex toOVertex({
    vm.Vector2? northCp,
    vm.Vector2? eastCp,
    vm.Vector2? southCp,
    vm.Vector2? westCp,
  }) =>
      OVertex.offset(this)
        ..northCp = northCp
        ..eastCp = eastCp
        ..southCp = southCp
        ..westCp = westCp;
}

/// Extension on [double] to convert it to an [OVertex].
extension DoubleDoubleToOVertex on (double, double) {
  /// Converts a double tuple to an [OVertex].
  OVertex get v => OVertex($1, $2);
}

/// Extension on [num] to convert it to an [OVertex].
extension NumNumToOVertex on (num, num) {
  /// Converts a num tuple to an [OVertex].
  OVertex get v => OVertex($1.toDouble(), $2.toDouble());
}

/// Extension on [OVertex] to create a new [OVertex] with bezier control points.
extension BezierizeOVertex on OVertex {
  /// Returns a new [OVertex] with the given control points.
  ///
  /// This overrides the control points of the current [OVertex],
  /// being `null` if not provided.
  OVertex bezier({
    vm.Vector2? north,
    vm.Vector2? east,
    vm.Vector2? south,
    vm.Vector2? west,
  }) {
    return this
      ..eastCp = east
      ..northCp = north
      ..southCp = south
      ..westCp = west;
  }
}
