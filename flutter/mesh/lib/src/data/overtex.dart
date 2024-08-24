import 'dart:math';
import 'dart:ui' as ui;

/// A vertex with `x` and `y` components.
///
/// Use shorthand initializers to create a new [OVertex] via one of the
/// following extensions:
/// - `(0.0, 0.0).v` => `OVertex(0.0, 0.0)`
/// - `(0, 0).v`  => `OVertex(0.0, 0.0)`
///
/// An [OVertex] can be created from instances of other classes:
/// - `Offset(0.0, 0.0).toOVertex()`
///
/// See also:
/// - [BezierOVertex], a vertex with bezier control points for each direction
///  on a rectangular mesh.
class OVertex {
  /// Creates a new [OVertex] with the given [x] and [y] values.
  OVertex(this.x, this.y);

  /// Creates a new zeroed and empty [OVertex].
  OVertex.zero()
      : x = 0.0,
        y = 0.0;

  /// Creates a new [OVertex] from an [ui.Offset].
  OVertex.offset(ui.Offset offset)
      : x = offset.dx,
        y = offset.dy;

  /// Creates a new [OVertex] with the same `x` and `y` values.
  OVertex.all(double xy)
      : x = xy,
        y = xy;

  /// Creates a copy of the given [OVertex].
  OVertex.copy(OVertex other)
      : x = other.x,
        y = other.y;

  /// Linearly interpolates between two [OVertex] objects.
  factory OVertex.lerp(OVertex a, OVertex b, double t) {
    return a.lerpTo(b, t);
  }

  /// Creates an [BezierOVertex] with the given control points.
  factory OVertex.bezier({
    required OVertex position,
    OVertex? north,
    OVertex? east,
    OVertex? south,
    OVertex? west,
  }) {
    return BezierOVertex(
      position.x,
      position.y,
      north: north,
      east: east,
      south: south,
      west: west,
    );
  }

  /// The x component of the offset.
  ///
  /// The y component is given by [y].
  double x;

  /// The y component of the offset.
  ///
  /// The x component is given by [x].
  double y;

  /// Create a copy of this OVertex.
  OVertex clone() => OVertex.copy(this);

  /// Converts this [OVertex] to an [ui.Offset].
  ui.Offset toOffset() => ui.Offset(x, y);

  /// Linearly interpolate between two [OVertex] objects.
  OVertex lerpTo(OVertex to, double t) {
    return OVertex.zero()
      ..x = ((to.x - x) / t) + x
      ..y = ((to.y - y) / t) + y;
  }

  /// Compute the euclidian distance between [other] and this.
  double distanceTo(OVertex other) {
    return sqrt(pow(other.x - x, 2) + pow(other.y - y, 2));
  }

  /// Unary negation operator.
  OVertex operator -() => clone()
    ..x = -x
    ..y = -y;

  /// Binary addition operator.
  OVertex operator +(OVertex other) => clone()
    ..x += other.x
    ..y += other.y;

  /// Binary subtraction operator.
  OVertex operator -(OVertex other) => clone()
    ..x -= other.x
    ..y -= other.y;

  /// Binary multiplication operator.
  OVertex operator *(double scale) => clone()
    ..x /= scale
    ..y /= scale;

  /// Check if two vectors are the same.
  @override
  bool operator ==(Object other) =>
      other is OVertex && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Extension on [ui.Offset] to convert it to an [OVertex].
extension OffsetToOVertex on ui.Offset {
  /// Converts an [ui.Offset] to an [OVertex]
  OVertex toOVertex() => OVertex.offset(this);
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

/// A vertex with bezier control points.
///
/// It extends [OVertex] and adds control points for each
/// direction on a rectangular mesh.
///
/// The control points are used to create bezier curves between vertices.
///
/// The widget will infer the position of the control points if
/// they are not provided.
///
/// Use shorthand initializers to create a new [BezierOVertex] via one of the
/// following extensions:
/// - `(0.0, 0.0).v.bezier(north: (0.0, 0.0).v)`
///   => `BezierOVertex(0.0, 0.0, north: OVertex(0.0, 0.0))`
///
/// An [BezierOVertex] can be created from instances of other classes:
/// - `Offset(0.0, 0.0).toOVertex().bezier(south: (0.0, 0.0).v)`
class BezierOVertex extends OVertex {
  /// Creates a new [BezierOVertex] with the given [x] and [y] values,
  /// and control points for each direction.
  BezierOVertex(
    super.x,
    super.y, {
    this.north,
    this.east,
    this.south,
    this.west,
  });

  /// Creates a new zeroed and empty [BezierOVertex].
  BezierOVertex.zero()
      : north = null,
        east = null,
        south = null,
        west = null,
        super.zero();

  /// Creates a new [BezierOVertex] from an [ui.Offset].
  BezierOVertex.offset(
    super.offset, {
    this.north,
    this.east,
    this.south,
    this.west,
  }) : super.offset();

  /// Creates a new [BezierOVertex] with the same `x` and `y` values.
  BezierOVertex.all(
    super.xy, {
    this.north,
    this.east,
    this.south,
    this.west,
  }) : super.all();

  /// Creates a new [BezierOVertex] from an [OVertex].
  BezierOVertex.oVertex(
    OVertex vertex, {
    this.north,
    this.east,
    this.south,
    this.west,
  }) : super(vertex.x, vertex.y);

  /// Creates a copy of the given [BezierOVertex].
  BezierOVertex.copy(BezierOVertex super.other)
      : north = other.north,
        east = other.east,
        south = other.south,
        west = other.west,
        super.copy();

  /// The bezier control point for the north direction.
  OVertex? north;

  /// The bezier control point for the east direction.
  OVertex? east;

  /// The bezier control point for the south direction.
  OVertex? south;

  /// The bezier control point for the west direction.
  OVertex? west;

  @override
  BezierOVertex clone() => BezierOVertex.copy(this);

  /// Converts this [BezierOVertex] to an [OVertex].
  OVertex toOVertex() => OVertex(x, y);

  @override
  BezierOVertex lerpTo(OVertex to, double t) {
    final lerped = BezierOVertex.zero()
      ..x = ((to.x - x) / t) + x
      ..y = ((to.y - y) / t) + y;
    if (to is! BezierOVertex) {
      return lerped;
    }
    return lerped
      ..north = north?.lerpTo(to.north!, t)
      ..east = east?.lerpTo(to.east!, t)
      ..south = south?.lerpTo(to.south!, t)
      ..west = west?.lerpTo(to.west!, t);
  }

  @override
  BezierOVertex operator -() => clone()
    ..x = -x
    ..y = -y
    ..north = north != null ? -north! : null
    ..east = east != null ? -east! : null
    ..south = south != null ? -south! : null
    ..west = west != null ? -west! : null;

  @override
  BezierOVertex operator +(OVertex other) => clone()
    ..x += other.x
    ..y += other.y
    ..north = north != null ? north! + other : null
    ..east = east != null ? east! + other : null
    ..south = south != null ? south! + other : null
    ..west = west != null ? west! + other : null;

  @override
  BezierOVertex operator -(OVertex other) => clone()
    ..x -= other.x
    ..y -= other.y
    ..north = north != null ? north! - other : null
    ..east = east != null ? east! - other : null
    ..south = south != null ? south! - other : null
    ..west = west != null ? west! - other : null;

  @override
  BezierOVertex operator *(double scale) => clone()
    ..x *= scale
    ..y *= scale
    ..north = north != null ? north! * scale : null
    ..east = east != null ? east! * scale : null
    ..south = south != null ? south! * scale : null
    ..west = west != null ? west! * scale : null;

  @override
  bool operator ==(Object other) =>
      other is BezierOVertex &&
      x == other.x &&
      y == other.y &&
      north == other.north &&
      east == other.east &&
      south == other.south &&
      west == other.west;

  @override
  int get hashCode => Object.hash(x, y, north, east, south, west);
}

/// Extension on [OVertex] to create a new [OVertex] with bezier control points.
extension BezierizeOVertex on OVertex {
  /// Returns a new [OVertex] with the given control points.
  ///
  /// This overrides the control points of the current [OVertex],
  /// being `null` if not provided.
  BezierOVertex bezier({
    OVertex? north,
    OVertex? east,
    OVertex? south,
    OVertex? west,
  }) =>
      BezierOVertex.oVertex(
        this,
        north: north,
        east: east,
        south: south,
        west: west,
      );
}
