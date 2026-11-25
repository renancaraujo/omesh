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

    const base = OMeshGrain(
      amount: 0.1,
      scatter: 4,
      shadows: 0.2,
      midtones: 0.3,
      highlights: 0.4,
      seed: 5,
    );
    final changes = <String, OMeshGrain>{
      'amount': base.copyWith(amount: 0.2),
      'scatter': base.copyWith(scatter: 8),
      'shadows': base.copyWith(shadows: 0.9),
      'midtones': base.copyWith(midtones: 0.9),
      'highlights': base.copyWith(highlights: 0.9),
      'seed': base.copyWith(seed: 6),
    };

    test('equality and hashCode', () {
      const same = OMeshGrain(
        amount: 0.1,
        scatter: 4,
        shadows: 0.2,
        midtones: 0.3,
        highlights: 0.4,
        seed: 5,
      );
      expect(base, same);
      expect(base.hashCode, same.hashCode);
      for (final MapEntry(:key, :value) in changes.entries) {
        expect(value, isNot(base), reason: key);
        expect(value.hashCode, isNot(base.hashCode), reason: key);
      }
    });

    test('copyWith replaces only the given field', () {
      double field(OMeshGrain grain, String name) => switch (name) {
            'amount' => grain.amount,
            'scatter' => grain.scatter,
            'shadows' => grain.shadows,
            'midtones' => grain.midtones,
            'highlights' => grain.highlights,
            _ => grain.seed.toDouble(),
          };
      for (final MapEntry(key: changed, value: copy) in changes.entries) {
        for (final name in changes.keys) {
          if (name == changed) {
            expect(field(copy, name), isNot(field(base, name)), reason: name);
          } else {
            expect(
              field(copy, name),
              field(base, name),
              reason: '$name after copyWith($changed)',
            );
          }
        }
      }
      expect(base.copyWith(), base);
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
