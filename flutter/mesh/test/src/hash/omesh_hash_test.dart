import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/hash.dart';
import 'package:mesh/mesh.dart';

final simpleOMesh = OMeshRect(
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
);

final complexOMesh = OMeshRect(
  width: 5,
  height: 5,
  fallbackColor: const Color(0xffade3fa),
  backgroundColor: const Color(0xffcae3ec),
  vertices: [
    (-0.06, -0.01).v,
    (0.24, -0.07).v,
    (0.51, -0.11).v,
    (0.74, -0.05).v,
    (1.03, -0.02).v, // Row 1

    (-0.04, 0.34).v,
    (0.25, 0.29).v,
    (0.51, 0.17).v,
    (0.75, 0.25).v,
    (1.03, 0.27).v, // Row 2

    (-0.05, 0.44).v,
    (0.15, 0.61).v.bezier(
          east: (0.25, 0.57).v,
          west: (0.05, 0.65).v,
        ),
    (0.48, 0.44).v.bezier(
          east: (0.66, 0.43).v,
          west: (0.3, 0.47).v,
        ),
    (0.81, 0.51).v.bezier(
          east: (0.89, 0.51).v,
          west: (0.68, 0.48).v,
        ),
    (1.03, 0.4).v, // Row 3

    (-0.06, 0.67).v,
    (0.15, 0.65).v.bezier(
          east: (0.25, 0.61).v,
          west: (0.07, 0.68).v,
        ),
    (0.48, 0.54).v.bezier(
          east: (0.69, 0.55).v,
          west: (0.28, 0.56).v,
        ),
    (0.92, 0.67).v.bezier(
          north: (0.92, 0.6).v,
        ),
    (1.03, 0.7).v, // Row 4

    (-0.03, 1.04).v,
    (0.35, 1.02).v,
    (0.65, 1.06).v,
    (0.93, 1.02).v,
    (1.07, 1.03).v, // Row 5
  ],
  colors: const [
    null,
    null,
    null,
    null,
    null, // Row 1

    Color(0xffeef8ff),
    Color(0xffd5ebff),
    Color(0xffedf5ff),
    Color(0xffedf5ff),
    Color(0xffedf5ff), // Row 2

    Color(0x73efe8ff),
    Color(0x73efe8ff),
    Color(0x54efe8ff),
    Color(0x73efe8ff),
    Color(0x73efe8ff), // Row 3

    Color(0xff003e48),
    Color(0xff00495b),
    Color(0xff004e5b),
    Color(0xff004e5b),
    Color(0xff004e5b), // Row 4

    Color(0xf7010c0c),
    Color(0xf7011515),
    Color(0xf7011e1e),
    Color(0xf7013131),
    Color(0xff025352), // Row 5
  ],
);

void main() {
  test('encodes and decodes a simple mesh', () {
    final hash = getHashFromMesh([simpleOMesh]);

    expect(
      hash,
      equals(
        '''
eJxj8vdlZGRgZt6_bkfg61a5Hfu3VD10XydSzWD_qD9G4-uh_v0rZ4LALAb7r4dAIoftl0BV7J8CYdhfvs5lW7D4OoP9HZCGGE37JxCawf4jVMtNqBn7W6BaPsBUQBn2HxggwP4D2BlB9s_BtscwMHAyMCzVzvjPwOg2eeV_BiYwybxUe8F_BpYXt678Z2AFi7BNF135n4EdzOYAkcwMAM0AYso=''',
      ),
    );

    final mesh = getMeshFromHash(hash);

    expect(mesh, [simpleOMesh]);
  });

  test('encodes and decodes a complex mesh', () {
    final hash = getHashFromMesh([complexOMesh]);

    expect(
      hash,
      equals(
        '''
eJxlkD8sQ1EUxr-nqT9P_X_FVGuNYuaMrQFRtnY2V2yszF0sDBYWgyY2g-QlFYsgShAhjapWpS01VMVy5d577jM4w3n33nfOd37na5mdtiz4_W76cK6yHjp011bykbSzCrrghwOZ56qgJ3WPuUfhRiaVGAW9ph1Z7O5tytgC1XWvu8Ea7q4-0E0mlQg3jkGXUEFX8p5JeaJ0YirKXMGVnihlI3JcFGYcPRqO43EVVJCglXXbm_I8kdy5syfIdLycyTinnF7NKNhUVI0j9KAV6JoVc2pBh960B4bWpipDGfyixveUDfQ9W2PspaIiWvqDZqY_aN6C2Pd_0nntg00lhsvzdlluyPO3pkeZkZb3UODRBrK0qALutqGXdcld0K3-Q3W9JjwH69K48BeoxnRexSdbyeKAA__7txBovakIgbZaQwi0q9yhsv1RFsvoVDnwURYL6FLnbpV7MBkV6MVUXKAPM3GBfpUHVHasQKCJoBUMNjFohUJNDFljY00Mt8zHhM8H7Bd-BHBaqIpf3kxZ_A==''',
      ),
    );

    final mesh = getMeshFromHash(hash);

    expect(mesh, [complexOMesh]);
  });
}
