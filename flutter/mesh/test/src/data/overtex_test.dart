import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';

void main() {
  group('$OVertex', () {
    group('constructors', () {
      test('OVertex.zero', () {
        final vertex = OVertex.zero();
        expect(vertex.x, 0.0);
        expect(vertex.y, 0.0);
      });

      test('OVertex', () {
        final vertex = OVertex(1, 2);
        expect(vertex.x, 1.0);
        expect(vertex.y, 2.0);
      });

      test('OVertex.offset', () {
        final vertex = OVertex.offset(const Offset(1, 2));
        expect(vertex.x, 1.0);
        expect(vertex.y, 2.0);
      });

      test('OVertex.all', () {
        final vertex = OVertex.all(1);
        expect(vertex.x, 1.0);
        expect(vertex.y, 1.0);
      });

      test('OVertex.copy', () {
        final vertex = OVertex(1, 2);
        final copy = OVertex.copy(vertex);
        expect(copy.x, 1.0);
        expect(copy.y, 2.0);
      });
    });

    group('equals', () {
      test('==', () {
        final vertex1 = OVertex(1, 2);
        final vertex2 = OVertex(1, 2);
        expect(vertex1, vertex2);
      });

      test('!=', () {
        final vertex1 = OVertex(1, 2);
        final vertex2 = OVertex(2, 1);
        expect(vertex1, isNot(vertex2));
      });
    });

    group('clone', () {
      test('clone', () {
        final vertex = OVertex(1, 2);
        final clone = vertex.clone();
        expect(clone, vertex);
        expect(clone, isNot(same(vertex)));
      });
    });

    group('toOffset', () {
      test('toOffset', () {
        final vertex = OVertex(1, 2);
        final offset = vertex.toOffset();
        expect(offset.dx, 1.0);
        expect(offset.dy, 2.0);
      });
    });

    group('lerpTo', () {
      test('lerpTo', () {
        final vertex = OVertex(1, 2);
        final lerp = vertex.lerpTo(OVertex(2, 4), 0.5);
        expect(lerp.x, 1.5);
        expect(lerp.y, 3.0);

        final lerpEp1 = vertex.lerpTo(OVertex(2, 4), -0.5);

        expect(lerpEp1.x, 0.5);
        expect(lerpEp1.y, 1.0);

        final lerpEp2 = vertex.lerpTo(OVertex(2, 4), 1.5);
        expect(lerpEp2.x, 2.5);
        expect(lerpEp2.y, 5.0);
      });
    });

    group('negate', () {
      test('negate', () {
        final vertex = OVertex(1, 2);
        final negated = -vertex;
        expect(negated.x, -1.0);
        expect(negated.y, -2.0);
      });
    });

    group('plus', () {
      test('plus', () {
        final vertex = OVertex(1, 2);
        final added = vertex + OVertex(1, 2);
        expect(added.x, 2.0);
        expect(added.y, 4.0);
      });
    });

    group('minus', () {
      test('minus', () {
        final vertex = OVertex(1, 2);
        final subtracted = vertex - OVertex(1, 2);
        expect(subtracted.x, 0.0);
        expect(subtracted.y, 0.0);
      });
    });

    group('multiply', () {
      test('multiply', () {
        final vertex = OVertex(1, 2);
        final scaled = vertex * 2;
        expect(scaled.x, 2.0);
        expect(scaled.y, 4.0);
      });
    });
  });

  group('$BezierOVertex', () {
    group('constructors', () {
      test('BezierOVertex', () {
        final vertex = BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(1, 2),
        );

        expect(vertex.x, 1.0);
        expect(vertex.y, 2.0);
        expect(vertex.north, OVertex(1, 2));
        expect(vertex.east, OVertex(1, 2));
        expect(vertex.south, null);
        expect(vertex.west, null);
      });

      test('BezierOVertex.zero', () {
        final vertex = BezierOVertex.zero();
        expect(vertex.x, 0.0);
        expect(vertex.y, 0.0);
        expect(vertex.north, null);
        expect(vertex.east, null);
        expect(vertex.south, null);
        expect(vertex.west, null);
      });

      test('BezierOVertex.all', () {
        final vertex = BezierOVertex.all(1);
        expect(vertex.x, 1.0);
        expect(vertex.y, 1.0);
        expect(vertex.north, null);
        expect(vertex.east, null);
        expect(vertex.south, null);
        expect(vertex.west, null);
      });

      test('BezierOVertex.offset', () {
        final vertex = BezierOVertex.offset(
          const Offset(1, 2),
          west: OVertex(2, 1),
          south: OVertex(2, 1),
        );

        expect(vertex.x, 1.0);
        expect(vertex.y, 2.0);
        expect(vertex.north, null);
        expect(vertex.east, null);
        expect(vertex.south, OVertex(2, 1));
        expect(vertex.west, OVertex(2, 1));
      });

      test('BezierOVertex.oVertex', () {
        final vertex = BezierOVertex.oVertex(
          OVertex(1, 2),
          west: OVertex(2, 1),
          south: OVertex(2, 1),
        );

        expect(vertex.x, 1.0);
        expect(vertex.y, 2.0);
        expect(vertex.north, null);
        expect(vertex.east, null);
        expect(vertex.south, OVertex(2, 1));
        expect(vertex.west, OVertex(2, 1));
      });

      test('BezierOVertex.copy', () {
        final vertex = BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(1, 2),
        );

        final copy = BezierOVertex.copy(vertex);
        expect(copy.x, 1.0);
        expect(copy.y, 2.0);
        expect(copy.north, OVertex(1, 2));
        expect(copy.east, OVertex(1, 2));
        expect(copy.south, null);
        expect(copy.west, null);
      });
    });

    group('equals', () {
      test('==', () {
        final vertex1 = BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(2, 2),
          south: OVertex(1, 1),
          west: OVertex(2, 1),
        );

        final vertex2 = BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(2, 2),
          south: OVertex(1, 1),
          west: OVertex(2, 1),
        );

        expect(vertex1, vertex2);
      });

      test('!=', () {
        final vertex1 = BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(2, 2),
          south: OVertex(1, 1),
          west: OVertex(2, 1),
        );

        final vertex2 = BezierOVertex(
          2,
          1,
          north: OVertex(2, 1),
          east: OVertex(1, 1),
          south: OVertex(2, 2),
          west: OVertex(1, 2),
        );

        expect(vertex1, isNot(vertex2));
      });
    });

    group('clone', () {
      test('clone', () {
        final vertex = BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(1, 2),
          south: OVertex(1, 2),
          west: OVertex(1, 2),
        );

        final clone = vertex.clone();
        expect(clone, vertex);
        expect(clone, isNot(same(vertex)));
      });
    });

    group('toOVertex', () {
      test('toOVertex', () {
        final vertex = BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(1, 2),
          south: OVertex(1, 2),
          west: OVertex(1, 2),
        );

        final oVertex = vertex.toOVertex();
        expect(oVertex.x, 1.0);
        expect(oVertex.y, 2.0);
      });
    });

    group('lerpTo', () {
      test('lerpTo', () {
        final vertex = BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(1, 2),
          south: OVertex(1, 2),
          west: OVertex(1, 2),
        );

        final lerp = vertex.lerpTo(
          BezierOVertex(
            2,
            4,
            north: OVertex(2, 4),
            east: OVertex(2, 4),
            south: OVertex(2, 4),
            west: OVertex(2, 4),
          ),
          0.5,
        );

        expect(lerp.x, 1.5);
        expect(lerp.y, 3.0);
        expect(lerp.north, OVertex(1.5, 3));
        expect(lerp.east, OVertex(1.5, 3));
        expect(lerp.south, OVertex(1.5, 3));
        expect(lerp.west, OVertex(1.5, 3));

        final lerpEp1 = vertex.lerpTo(
          BezierOVertex(
            2,
            4,
            north: OVertex(2, 4),
            east: OVertex(2, 4),
            south: OVertex(2, 4),
            west: OVertex(2, 4),
          ),
          -0.5,
        );

        expect(lerpEp1.x, 0.5);
        expect(lerpEp1.y, 1.0);
        expect(lerpEp1.north, OVertex(0.5, 1));
        expect(lerpEp1.east, OVertex(0.5, 1));
        expect(lerpEp1.south, OVertex(0.5, 1));
        expect(lerpEp1.west, OVertex(0.5, 1));

        final lerpEp2 = vertex.lerpTo(
          BezierOVertex(
            2,
            4,
            north: OVertex(2, 4),
            east: OVertex(2, 4),
            south: OVertex(2, 4),
            west: OVertex(2, 4),
          ),
          1.5,
        );

        expect(lerpEp2.x, 2.5);
        expect(lerpEp2.y, 5.0);
        expect(lerpEp2.north, OVertex(2.5, 5));
        expect(lerpEp2.east, OVertex(2.5, 5));
        expect(lerpEp2.south, OVertex(2.5, 5));
        expect(lerpEp2.west, OVertex(2.5, 5));
      });
    });

    group('negate', () {
      test('negate', () {
        final vertex = BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(1, 2),
          south: OVertex(1, 2),
          west: OVertex(1, 2),
        );

        final negated = -vertex;
        expect(negated.x, -1.0);
        expect(negated.y, -2.0);
        expect(negated.north, OVertex(-1, -2));
        expect(negated.east, OVertex(-1, -2));
        expect(negated.south, OVertex(-1, -2));
        expect(negated.west, OVertex(-1, -2));
      });
    });

    group('plus', () {
      test('plus', () {
        final vertex = BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(1, 2),
          south: OVertex(1, 2),
          west: OVertex(1, 2),
        );

        final added = vertex + BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(1, 2),
          south: OVertex(1, 2),
          west: OVertex(1, 2),
        );

        expect(added.x, 2.0);
        expect(added.y, 4.0);
        expect(added.north, OVertex(2, 4));
        expect(added.east, OVertex(2, 4));
        expect(added.south, OVertex(2, 4));
        expect(added.west, OVertex(2, 4));
      });
    });

    group('minus', () {
      test('minus', () {
        final vertex = BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(1, 2),
          south: OVertex(1, 2),
          west: OVertex(1, 2),
        );

        final subtracted = vertex - BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(1, 2),
          south: OVertex(1, 2),
          west: OVertex(1, 2),
        );

        expect(subtracted.x, 0.0);
        expect(subtracted.y, 0.0);
        expect(subtracted.north, OVertex(0, 0));
        expect(subtracted.east, OVertex(0, 0));
        expect(subtracted.south, OVertex(0, 0));
        expect(subtracted.west, OVertex(0, 0));
      });
    });

    group('multiply', () {
      test('multiply', () {
        final vertex = BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(1, 2),
          south: OVertex(1, 2),
          west: OVertex(1, 2),
        );

        final scaled = vertex * 2;
        expect(scaled.x, 2.0);
        expect(scaled.y, 4.0);
        expect(scaled.north, OVertex(2, 4));
        expect(scaled.east, OVertex(2, 4));
        expect(scaled.south, OVertex(2, 4));
        expect(scaled.west, OVertex(2, 4));
      });
    });
  });

  group('Offset To OVertex', () {
    test('toOVertex', () {
      const offset = Offset(1, 2);
      final vertex = offset.toOVertex();
      expect(vertex.x, 1.0);
      expect(vertex.y, 2.0);
    });
  });

  group('(double, double) To OVertex', () {
    test('v', () {
      final vertex = (1.0, 2.0).v;
      expect(vertex, OVertex(1, 2));
    });
  });

  group('(num, num) To OVertex', () {
    test('v', () {
      final vertex = (1, 2).v;
      expect(vertex, OVertex(1, 2));
    });
  });

  group('BezierizeOVertex', () {
    test('bezier', () {
      final vertex = OVertex(1, 2).bezier(
        north: OVertex(1, 2),
        east: OVertex(2, 2),
        south: OVertex(1, 1),
        west: OVertex(2, 1),
      );

      expect(
        vertex,
        BezierOVertex(
          1,
          2,
          north: OVertex(1, 2),
          east: OVertex(2, 2),
          south: OVertex(1, 1),
          west: OVertex(2, 1),
        ),
      );
    });
  });
}
