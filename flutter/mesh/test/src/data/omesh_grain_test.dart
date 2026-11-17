import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';

void main() {
  group('$OMeshGrain', () {
    test('default turns both effects on', () {
      const grain = OMeshGrain();
      expect(grain.amount, greaterThan(0));
      expect(grain.scatter, greaterThan(0));
      expect(grain.isActive, isTrue);
    });

    test('none is inactive', () {
      expect(OMeshGrain.none.isActive, isFalse);
      expect(OMeshGrain.none.amount, 0);
      expect(OMeshGrain.none.scatter, 0);
    });

    test('equality and hashCode', () {
      const a = OMeshGrain(amount: 0.1, seed: 3);
      const b = OMeshGrain(amount: 0.1, seed: 3);
      const c = OMeshGrain(amount: 0.1, seed: 4);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('copyWith replaces only the given fields', () {
      const grain = OMeshGrain();
      final copy = grain.copyWith(amount: 0.2, shadows: 0.3);
      expect(copy.amount, 0.2);
      expect(copy.shadows, 0.3);
      expect(copy.scatter, grain.scatter);
      expect(copy.seed, grain.seed);
    });

    group('lerp', () {
      const a = OMeshGrain.none;
      const b = OMeshGrain(amount: 0.2, scatter: 10, seed: 5);

      test('interpolates amounts and switches the seed halfway', () {
        final early = OMeshGrain.lerp(a, b, 0.25)!;
        expect(early.amount, closeTo(0.05, 1e-9));
        expect(early.scatter, closeTo(2.5, 1e-9));
        expect(early.seed, 0);

        final late = OMeshGrain.lerp(a, b, 0.75)!;
        expect(late.seed, 5);
      });

      test('treats null as none and never goes negative', () {
        final fromNull = OMeshGrain.lerp(null, b, 0.5)!;
        expect(fromNull.amount, closeTo(0.1, 1e-9));
        final overshoot = OMeshGrain.lerp(b, a, 1.2)!;
        expect(overshoot.amount, 0);
        expect(overshoot.scatter, 0);
        expect(OMeshGrain.lerp(null, null, 0.5), isNull);
      });
    });
  });
}
