import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/hash.dart';
import 'package:mesh/mesh.dart';

typedef _Fixture = ({
  String name,
  OMeshRect mesh,
  String v1Hash,
  String v2Hash,
});

final _verySimpleOMesh = OMeshRect(
  width: 2,
  height: 2,
  vertices: [
    (0.0, 0.0).v, (1.0, 0.0).v, // Row 1
    (0.0, 1.0).v, (1.0, 1.0).v, // Row 2
  ],
  colors: const [
    null, Color(0xff4693a9), // Row 1
    null, Color(0xff4693a9), // Row 2
  ],
);

final _simpleOMesh = OMeshRect(
  width: 3,
  height: 3,
  vertices: [
    (0.00, -0.08).v,
    (0.58, -0.05).v,
    (1.36, 0.04).v, // Row 1

    (0.00, 0.31).v,
    (0.44, 0.63).v,
    (1.11, 0.4).v, // Row 2

    (0.0, 1.01).v,
    (1.0, 1.0).v,
    (1.0, 0.73).v, // Row 3
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

final _customOMesh = OMeshRect(
  width: 5,
  height: 4,
  colorSpace: OMeshColorSpace.xyY,
  fallbackColor: const Color(0xff0e0e0e),
  vertices: [
    (-0.07, -0.04).v, (0.27, -0.07).v, (0.52, -0.08).v, (0.79, -0.07).v,
    (1.08, -0.08).v, // Row 1
    (-0.02, 0.41).v.bezier(
          north: (-0.03, 0.3).v,
          east: (0.15, 0.43).v,
        ),
    (0.52, 0.48).v.bezier(
          north: (0.54, 0.26).v,
          west: (0.38, 0.39).v,
        ),
    (0.57, 0.6).v.bezier(
          north: (0.66, 0.42).v,
          east: (0.69, 0.65).v,
          west: (0.52, 0.56).v,
        ),
    (0.75, 0.33).v.bezier(
          south: (0.8, 0.53).v,
        ),
    (1, 0.33).v, // Row 2
    (0, 0.67).v,
    (0.4, 0.6).v.bezier(
          south: (0.29, 0.62).v,
        ),
    (0.51, 0.71).v,
    (0.75, 0.67).v,
    (1, 0.67).v, // Row 3
    (-0.15, 1.09).v, (0.23, 1.08).v, (0.5, 1.1).v, (0.77, 1.14).v,
    (1.06, 1.06).v, // Row 4
  ],
  colors: const [
    Color(0xffc1aaa2), Color(0xffff0018), Color(0xffff0053),
    Color(0xffffb266), Color(0xffd3ff60), // Row 1
    Color(0xffff0053), Color(0xffff0053), Color(0xffff70c8),
    Color(0xffff0053), Color(0xffff0053), // Row 2
    Color(0xffff0053), Color(0xffff70c8), Color(0xffff0053),
    Color(0xffff0053), Color(0xffff0053), // Row 3
    Color(0xff9883a9), Color.fromARGB(255, 34, 16, 16), Color(0xffde9a9a),
    Color(0xffde9a9a), Color(0xffde9a9a), // Row 4
  ],
);

final _complexOMesh = OMeshRect(
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

const _displayP3Color = Color.from(
  alpha: 1,
  red: 0.4,
  green: 0.59,
  blue: 0.65,
  colorSpace: ColorSpace.displayP3,
);

final _colorSpacesOMesh = OMeshRect(
  width: 3,
  height: 3,
  colorSpace: OMeshColorSpace.xyY,
  fallbackColor: const Color(0xff0e0e0e),
  vertices: [
    (0.00, -0.08).v,
    (0.58, -0.05).v,
    (1.36, 0.04).v, // Row 1

    (0.00, 0.31).v,
    (0.44, 0.63).v,
    (1.11, 0.4).v, // Row 2

    (0.0, 1.01).v,
    (1.0, 1.0).v,
    (1.0, 0.73).v, // Row 3
  ],
  colors: const [
    Color(0xffa52b68),
    _displayP3Color,
    Color(0xff4693a9), // Row 1

    Color(0xffa52ba0),
    null,
    _displayP3Color, // Row 2

    Color(0xff9715a9),
    null,
    _displayP3Color, // Row 3
  ],
);

final List<_Fixture> _fixtures = [
  (
    name: 'a very simple mesh',
    mesh: _verySimpleOMesh,
    v1Hash: 'OM:eJxjVGJAB_YfMITQJGAMuAAjg9vklf8ZGBkYDQDHZweU',
    v2Hash: 'OM:gmNi4mRAAEYOt8krGRgZGAE',
  ),
  (
    name: 'a simple mesh',
    mesh: _simpleOMesh,
    v1Hash: '''
OM:eJxjNGaAgv1bqh66rxOpZrB_1B-j8fVQ__6VM0FgFoP910MgkcP2S6AqYMD-8nUu24LF1xns74A0xGjaP4HQDPYfoVpuQs2Aa_kAU_EBJsCAyrB_DrY9hoGVYal2xn8Gt8kr_zMs1V7wn-HFrSv_GaaLrvzPyMTEzMLEysRkAAA5OUWE''',
    v2Hash: '''
OM:gmNm5mRiAAN-AU4PDgZVbikxYQamFAYGU1aOpdoZHG6TVwLpBRwvbl3hmC66kpGJiZmFiZWJCQA''',
  ),
  (
    name: 'a custom mesh',
    mesh: _customOMesh,
    v1Hash: '''
OM:eJxdUDtMAkEQHTz8nCaEgsJKEyt6a_JKbFELCwora2yxNNQ0FnqFhdBoQaKxoLuIjYUkIjEgJuROhECwOEywHbM3uyTykrvdzL7PzET23dtxYaOa-XbLeT9dSZwQGulKIu_vmAeCV2qtpnJl994wRvOMiS4YhnsmF3RSOSW23MtqRpHR3A6BR31-KIdxwWSgKzwbvljiRT-0w_ou2tNaMZv8xac4oydGa-iHRpvoiBKDRNgDvp4V6rMEX5rGkELgTXRRjC4UHHg6IfhPIAP0w-RjwrtW6B6ieC1mk9NaET0VVWrB000PZCqahc4sgrmCaxYzMYy6XMyOCZ6WTCSdMNST_chKCIGZQE6y6eHmiolpXf32mPjuiKnJh0yce2I6P71m2orHmbqOw5EFK7poWUuWfMsrtm0fUCwW4z8wNfJn''',
    v2Hash: '''
OM:gmNlkWJiYDDYyeLAAAS87Cy8LPwcvAL8zAKMokosZnIs2tKCfGZCyhJcnOwMDFwaIFVyvKIsTBwglqwQswCDCIsMDw8nx8FVizj-M0gAcTDH_01pHJf_J3D8LzjBMaN5JYeSgADHvVmzGJmYWViZmdmYIZidg5OTk4OPjw8A''',
  ),
  (
    name: 'a complex mesh',
    mesh: _complexOMesh,
    v1Hash: '''
OM:eJxlkDFMwkAUhl-hKlbYYMUVR-IqvhFcTECdYHbGuOkqM4uLDi6yOEjixmByCcTFqBENGqMh1gpioIoD1ricubt3ZfAN1177v_997zfWWLWW7ZfiNbazZaer0W3AK_pwIs7sAPBZ3nPsNDGqlwtzgG_VqBCzoz1R-4BD1ct2yYNV1Au26uVCYtQAvAZZeCPu9bJvimda0SMFKX1TbKbFuAzocfikORrzstARoP2S5U95SRUP760U6o7XC1GX2FaraQcLO7JxFh-VA96SY1suGMV3lYGmtXBAUBq_o_B9Zw39QNHoeLEjiTbG0MQ0hqYtkHL_Z22rHCzsEpxN2zWpwaanq0bpkYb_waHRGrK7LgvYgaYXumIF8E79waFaE_wEhyK4xDegS3S-4ouiJHOIwMcP59Dqcw7uiHP47PFNcawCLGY4wFKeAyznORjhsAdGLOaBEY97YCSTHgRWclzGYgSCwaBpTpjm5FQoFJq2ZsKRBTh2fjmcOwP-ByMVREc''',
    v2Hash: '''
OM:gh3OKw7CQBSF4TvvO8wMQ5iWBFMBTQg4JAYNBgG4LoMNoZuwETwrqCHhpUgJZmg54jv2F2JBod2xhJI0bwhxNCVaMtUHpB5Acm3CIFEBmcnJWFrag6GQwfgQEuUlm87ohI88OKkFJjyzOe9Kh89PxMst4uMd4XWNh5Y9wnKFsC4QNgUQa2sgadqQZQ3zeY10t_33EMoY41xwLhUi6o6xDk_VF8_V_Qc''',
  ),
  (
    name: 'a mesh with colors with different color spaces',
    mesh: _colorSpacesOMesh,
    v1Hash: '''
OM:eJxjNGaAgv1bqh66rxOpZrB_1B-j8fVQ__6VM0FgFoP910MgkcP2S6AqYMD-8nUu24LF1xns74A0xGjaP4HQDPYfoVpuQs2Aa_kAU_EBJsCAyrB_DrY9hoGVYal2xn8mmBH2j0CWVz20f3IGBM7CNbpNXvmfYan2gv8M00VX_mdkYmZhYGJlYIpg4OPj-w8Ap0BTbg''',
    v2Hash: '''
OM:gmNmlmJiAAN-AU4PDgZVbikxYQamFAYGU1aOpdoZWgFlTYwnGDncJq8EchdwTBddycjEzMLAxMrAxMHHxwcA''',
  ),
];

/// A regular [width] x [height] mesh with coordinates offset by [offset]
/// and a different color on every vertex.
OMeshRect _grid(
  int width,
  int height, {
  double Function(int index)? offset,
  List<Color?>? colors,
}) {
  final count = width * height;
  return OMeshRect(
    width: width,
    height: height,
    vertices: [
      for (var i = 0; i < count; i++)
        (
          (i % width) / (width - 1) + (offset?.call(i) ?? 0),
          (i ~/ width) / (height - 1) - (offset?.call(i) ?? 0),
        ).v,
    ],
    colors: colors ??
        [
          for (var i = 0; i < count; i++)
            Color(0xff000000 | (i * 0x9e3779) & 0xffffff),
        ],
  );
}

OMeshRect _roundTrip(OMeshRect mesh, OMeshBinaryFormatCodec codec) {
  return codec.decode(codec.encode(mesh));
}

void main() {
  group('v1 hashes', () {
    for (final fixture in _fixtures) {
      test('of ${fixture.name} still decode', () {
        expect(getMeshFromHash(fixture.v1Hash), fixture.mesh);
      });

      // v1 hashes are zlib compressed with dart:io on native platforms and
      // with package:archive on the web, which produce different bytes.
      test(
        'of ${fixture.name} are still generated by the v1 codec',
        testOn: '!browser',
        () {
          expect(
            getHashFromMesh(fixture.mesh, codec: OMeshBinaryFormatCodec.v1),
            fixture.v1Hash,
          );
        },
      );
    }

    test('generated on the web still decode', () {
      expect(
        getMeshFromHash('OM:eAFjVGJAB_YfMITQJGAMuAAjg9vklf-BFKMBAMdnB5Q'),
        _verySimpleOMesh,
      );
    });
  });

  group('v2 hashes', () {
    for (final fixture in _fixtures) {
      test('encodes and decodes ${fixture.name}', () {
        final hash = getHashFromMesh(fixture.mesh);

        expect(hash, fixture.v2Hash);
        expect(getMeshFromHash(hash), fixture.mesh);
      });

      test('of ${fixture.name} are shorter than v1 hashes', () {
        expect(
          getHashFromMesh(fixture.mesh).length,
          lessThan(fixture.v1Hash.length),
        );
      });
    }

    test('are the default of OMeshRect.getHash', () {
      expect(_complexOMesh.getHash(), getHashFromMesh(_complexOMesh));
      expect(
        _complexOMesh.getHash(codec: OMeshBinaryFormatCodec.v1),
        getHashFromMesh(_complexOMesh, codec: OMeshBinaryFormatCodec.v1),
      );
      expect(
        OMeshRect.fromHash(hash: _complexOMesh.getHash()),
        _complexOMesh,
      );
    });
  });

  group('OMeshBinaryFormatCodec', () {
    test('every codec decodes every spec version', () {
      final v1Bytes = OMeshBinaryFormatCodec.v1.encode(_complexOMesh);
      final v2Bytes = OMeshBinaryFormatCodec.v2.encode(_complexOMesh);

      expect(v1Bytes.first, 1);
      expect(v2Bytes.first, 2);
      for (final codec in [
        OMeshBinaryFormatCodec.v1,
        OMeshBinaryFormatCodec.v2,
        const OMeshBinaryFormatCodec.v2Rounded(),
      ]) {
        expect(codec.decode(v1Bytes), _complexOMesh);
        expect(codec.decode(v2Bytes), _complexOMesh);
      }
    });

    test('throws on unknown spec versions', () {
      final bytes = OMeshBinaryFormatCodec.v2.encode(_simpleOMesh)..[0] = 99;

      expect(
        () => OMeshBinaryFormatCodec.v2.decode(bytes),
        throwsFormatException,
      );
      expect(
        () => getMeshFromHash(
          getHashFromMesh(_simpleOMesh).replaceRange(3, 4, 'Y'),
        ),
        throwsFormatException,
      );
    });

    group('v1', () {
      test('refuses meshes over 15 vertices in a dimension', () {
        expect(
          () => OMeshBinaryFormatCodec.v1.encode(_grid(16, 3)),
          throwsArgumentError,
        );
      });

      test('ignores vertices and colors beyond width * height', () {
        final mesh = _grid(3, 3);
        final withExtras = mesh.copyWith(
          vertices: [...mesh.vertices, (0.5, 0.5).v],
          colors: [...mesh.colors, const Color(0xffff0000)],
        );

        expect(_roundTrip(withExtras, OMeshBinaryFormatCodec.v1), mesh);
      });
    });

    group('v2', () {
      test('supports meshes up to the maximum dimension', () {
        final mesh = _grid(kMaxOMeshRectDimension, kMaxOMeshRectDimension);

        expect(_roundTrip(mesh, OMeshBinaryFormatCodec.v2), mesh);
        expect(getMeshFromHash(getHashFromMesh(mesh)), mesh);
      });

      test('supports odd vertex counts and negative coordinates', () {
        final mesh = _grid(3, 5, offset: (i) => -2.5 + i * 0.75);

        expect(_roundTrip(mesh, OMeshBinaryFormatCodec.v2), mesh);
      });

      test('ignores vertices and colors beyond width * height', () {
        final mesh = _grid(3, 3);
        final withExtras = mesh.copyWith(
          vertices: [...mesh.vertices, (0.5, 0.5).v],
          colors: [...mesh.colors, const Color(0xffff0000)],
        );

        expect(_roundTrip(withExtras, OMeshBinaryFormatCodec.v2), mesh);
      });

      test('keeps full precision coordinates exactly', () {
        final random = math.Random(7);
        final dragged = _grid(
          6,
          6,
          offset: (_) => random.nextDouble() * 0.01,
        );

        expect(_roundTrip(dragged, OMeshBinaryFormatCodec.v2), dragged);
        expect(getMeshFromHash(getHashFromMesh(dragged)), dragged);
      });

      test('keeps extreme coordinates exactly', () {
        final mesh = _grid(2, 2).copyWith(
          vertices: [
            (1 / 3, math.pi).v,
            (1e300, -1e-300).v,
            (-0.5, 1.5).v.bezier(
                  north: (double.infinity, double.negativeInfinity).v,
                ),
            (1, 1).v,
          ],
        );

        expect(_roundTrip(mesh, OMeshBinaryFormatCodec.v2), mesh);
        expect(
          _roundTrip(mesh, const OMeshBinaryFormatCodec.v2Rounded()),
          mesh,
        );
      });

      test('keeps colors exactly, including their color space', () {
        final mesh = _grid(
          3,
          2,
          colors: const [
            Color.from(
              alpha: 1,
              red: 1.2,
              green: -0.1,
              blue: 0.5,
              colorSpace: ColorSpace.extendedSRGB,
            ),
            Color.from(alpha: 0.5, red: 0.123456789, green: 0, blue: 1),
            Color.from(
              alpha: 0.3,
              red: 1 / 3,
              green: 2 / 3,
              blue: 0.999,
              colorSpace: ColorSpace.displayP3,
            ),
            Color(0x00000000),
            Color(0x80ff8000),
            null,
          ],
        );

        expect(_roundTrip(mesh, OMeshBinaryFormatCodec.v2), mesh);
        expect(getMeshFromHash(getHashFromMesh(mesh)), mesh);
      });

      test('keeps metadata', () {
        final mesh = _grid(2, 2).copyWith(
          colorSpace: OMeshColorSpace.linear,
          smoothColors: false,
          backgroundColor: _displayP3Color,
        );

        expect(_roundTrip(mesh, OMeshBinaryFormatCodec.v2), mesh);
      });

      test('throws on truncated data', () {
        final bytes = OMeshBinaryFormatCodec.v2.encode(_complexOMesh);

        expect(
          () => OMeshBinaryFormatCodec.v2.decode(
            Uint8List.sublistView(bytes, 0, bytes.length - 1),
          ),
          throwsA(anything),
        );
      });
    });

    group('v2Rounded', () {
      test('keeps coordinates that fit the decimal places exactly', () {
        for (final fixture in _fixtures) {
          expect(
            _roundTrip(
              fixture.mesh,
              const OMeshBinaryFormatCodec.v2Rounded(),
            ),
            fixture.mesh,
          );
        }
      });

      test('rounds coordinates that need more decimal places', () {
        final random = math.Random(7);
        final mesh = _grid(
          5,
          5,
          offset: (_) => random.nextDouble() * 0.01,
        );

        const codec = OMeshBinaryFormatCodec.v2Rounded();
        final decoded = _roundTrip(mesh, codec);

        expect(decoded, isNot(mesh));
        expect(decoded.colors, mesh.colors);
        for (var i = 0; i < mesh.vertices.length; i++) {
          final original = mesh.vertices[i];
          final rounded = decoded.vertices[i];
          expect(rounded.x, closeTo(original.x, 0.0005));
          expect(rounded.y, closeTo(original.y, 0.0005));
          expect(rounded.x, (original.x * 1000).round() / 1000);
          expect(rounded.y, (original.y * 1000).round() / 1000);
        }
        expect(
          getHashFromMesh(mesh, codec: codec).length,
          lessThan(getHashFromMesh(mesh).length),
        );
      });
    });
  });
}
