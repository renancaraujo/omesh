import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  group('$OVertex', () {
    group('constructors', () {
      test('OVertex.zero', () {
        final vertex = OVertex.zero();
        expect(vertex.x, 0.0);
        expect(vertex.y, 0.0);
        expect(vertex.northCp, isNull);
        expect(vertex.eastCp, isNull);
        expect(vertex.southCp, isNull);
        expect(vertex.westCp, isNull);
      });

      test('OVertex', () {
        final vertex = OVertex(1, 2);
        expect(vertex.x, 1.0);
        expect(vertex.y, 2.0);
        expect(vertex.northCp, isNull);
        expect(vertex.eastCp, isNull);
        expect(vertex.southCp, isNull);
        expect(vertex.westCp, isNull);
      });

      test('OVertex.vector2', () {
        final vertex = OVertex.vector2(vm.Vector2(1, 2));
        expect(vertex.x, 1.0);
        expect(vertex.y, 2.0);
        expect(vertex.northCp, isNull);
        expect(vertex.eastCp, isNull);
        expect(vertex.southCp, isNull);
        expect(vertex.westCp, isNull);
      });

      test('OVertex.offset', () {
        final vertex = OVertex.offset(const Offset(1, 2));
        expect(vertex.x, 1.0);
        expect(vertex.y, 2.0);
        expect(vertex.northCp, isNull);
        expect(vertex.eastCp, isNull);
        expect(vertex.southCp, isNull);
        expect(vertex.westCp, isNull);
      });

      test('OVertex.all', () {
        final vertex = OVertex.all(1);
        expect(vertex.x, 1.0);
        expect(vertex.y, 1.0);
        expect(vertex.northCp, isNull);
        expect(vertex.eastCp, isNull);
        expect(vertex.southCp, isNull);
        expect(vertex.westCp, isNull);
      });

      test('OVertex.copy', () {
        final vertex = OVertex(1, 2);
        final copy = OVertex.copy(vertex);
        expect(copy.x, 1.0);
        expect(copy.y, 2.0);
        expect(copy.northCp, isNull);
        expect(copy.eastCp, isNull);
        expect(copy.southCp, isNull);
        expect(copy.westCp, isNull);
      });
    });

    group('equals', () {
      test('==', () {
        final vertex1 = OVertex(1, 2)
          ..northCp = vm.Vector2(1, 2)
          ..eastCp = vm.Vector2(1, 2)
          ..southCp = vm.Vector2(1, 2)
          ..westCp = vm.Vector2(1, 2);
        final vertex2 = OVertex(1, 2)
          ..northCp = vm.Vector2(1, 2)
          ..eastCp = vm.Vector2(1, 2)
          ..southCp = vm.Vector2(1, 2)
          ..westCp = vm.Vector2(1, 2);
        expect(vertex1, vertex2);
      });

      test('!=', () {
        final vertex1 = OVertex(1, 2)
          ..northCp = vm.Vector2(1, 2)
          ..eastCp = vm.Vector2(1, 2)
          ..southCp = vm.Vector2(1, 2)
          ..westCp = vm.Vector2(1, 2);
        final vertex2 = OVertex(2, 1)
          ..northCp = vm.Vector2(1, 2)
          ..eastCp = vm.Vector2(1, 2)
          ..southCp = vm.Vector2(1, 2)
          ..westCp = vm.Vector2(1, 2);
        expect(vertex1, isNot(vertex2));
      });
    });

    group('clone', () {
      test('clone', () {
        final vertex = OVertex(1, 2)
          ..northCp = vm.Vector2(1, 2)
          ..eastCp = vm.Vector2(1, 2)
          ..southCp = vm.Vector2(1, 2)
          ..westCp = vm.Vector2(1, 2);
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
        final added = vertex + vm.Vector2(1, 2);
        expect(added.x, 2.0);
        expect(added.y, 4.0);
      });
    });

    group('minus', () {
      test('minus', () {
        final vertex = OVertex(1, 2);
        final subtracted = vertex - vm.Vector2(1, 2);
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

  group('Vector2 To OVertex', () {
    test('toOVertex', () {
      final vector = vm.Vector2(1, 2);
      final vertex = vector.toOVertex(
        northCp: vm.Vector2(1, 2),
        eastCp: vm.Vector2(1, 2),
        southCp: vm.Vector2(1, 2),
        westCp: vm.Vector2(1, 2),
      );
      expect(vertex.x, 1.0);
      expect(vertex.y, 2.0);
      expect(vertex.northCp, vm.Vector2(1, 2));
      expect(vertex.eastCp, vm.Vector2(1, 2));
      expect(vertex.southCp, vm.Vector2(1, 2));
      expect(vertex.westCp, vm.Vector2(1, 2));
    });
  });

  group('Offset To OVertex', () {
    test('toOVertex', () {
      const offset = Offset(1, 2);
      final vertex = offset.toOVertex(
        northCp: vm.Vector2(1, 2),
        eastCp: vm.Vector2(1, 2),
        southCp: vm.Vector2(1, 2),
        westCp: vm.Vector2(1, 2),
      );
      expect(vertex.x, 1.0);
      expect(vertex.y, 2.0);
      expect(vertex.northCp, vm.Vector2(1, 2));
      expect(vertex.eastCp, vm.Vector2(1, 2));
      expect(vertex.southCp, vm.Vector2(1, 2));
      expect(vertex.westCp, vm.Vector2(1, 2));
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

  group('Bezierize OVertex', () {
    test('bezierize', () {
      final vertex = OVertex(1, 2).bezier(
        north: vm.Vector2(1, 2),
        east: vm.Vector2(1, 2),
        south: vm.Vector2(1, 2),
        west: vm.Vector2(1, 2),
      );

      expect(
        vertex,
        OVertex(1, 2)
          ..northCp = vm.Vector2(1, 2)
          ..eastCp = vm.Vector2(1, 2)
          ..southCp = vm.Vector2(1, 2)
          ..westCp = vm.Vector2(1, 2),
      );
    });
  });
}
