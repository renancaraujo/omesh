import 'dart:convert';
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
    v1Hash: 'OM:eAFjVGJAB_YfMITQJGAMuAAjg9vklf-BFKMBAMdnB5Q',
    v2Hash: 'OM:wmNi4mRAAEYOt8krGRgZGAHepw',
  ),
  (
    name: 'a simple mesh',
    mesh: _simpleOMesh,
    v1Hash: '''
OM:eAFjNGaAgv1bqh66rxOpZrB_1B-j8fVQ__6VM0FgFoM9kAMUOWy_BKoCBuwvX-eyLVh8ncH-DkhDjKb9EwjNYP8RquUm1Ay4lg8wFR9gAgyoDPvnYNtjGFgZlmpn_Gdwm7zyP5C14D_Di1tX_jNMF135n5GJiZmFiZWJyQAAOTlFhA''',
    v2Hash: '''
OM:wmNm5mRiAAN-AU4PDgZVbikxYQamFAYGU1aOpdoZHG6TVwLpBRwvbl3hmC66kpGJiZmFiZWJCQC-Xw''',
  ),
  (
    name: 'a custom mesh',
    mesh: _customOMesh,
    v1Hash: '''
OM:eAFdUS1Mw0AUfqPlp5A0ExMoSFB49PJJsAMEAoFCFzskmcYgoALBZkCQQBBzDWAQLGEsZGMkS8vYwjLESgL2uOu7a8Je0nsv776fd6-ZzeBqWFqoFr6CSjFavcztE-oyFaM1c0EIy83ZvFcJbgxiMI6IdcMggiMu0M57imwFp9WCAqOxkgTudX5TCsOS8UCHcQ4ilsSTvmgl_XW0fu4Ot5d_8c7K6LLQHHqJ0CLazEQ_l8yAj0cVtdQh4qHxSUnghXk2BicqfITaYfQfQCbQS5z3CK-aoWew8SyJko2usio3Eeqh-_wqSk1TidFYIzCLiQ2ixoXZsfwdmhKzuxTVL_vmlUhR8wLO5NDtxZkgQfPq2JDH9a6ghtiRlfcg6PjgXNBSNiuo4_siM2HZk5Y1ZfE3PeM4zha5riv-ADA18mc''',
    v2Hash: '''
OM:wmNlkWJiYDDYyeLAAAS87Cy8LPwcvAL8zAKMokosZnIs2tKCfGZCyhJcnOwMDFwaIFVyvKIsTBwglqwQswCDCIsMDw8nx8FVizj-M0gAcTDH_01pHJf_J3D8LzjBMaN5JYeSgADHvVmzGJmYWViZmdmYIZidg5OTk4OPjw8Ab8Y''',
  ),
  (
    name: 'a complex mesh',
    mesh: _complexOMesh,
    v1Hash: '''
OM:eAFlkD9MwlAQxq9QFStssOKKI3EVbwQXE1AnnZ0xbrrKzOKig4ssDpK4MZg0gbgYNaJBYzTEWosYQHFAjEt9f-49Bm_4aMvdd7_7jBW7XMl2CvGKvbPlpMvRbcAr-nDCNdsFfBbvOfs0MagW12YA38pR3mwf7fHaB-zLWXuXPOySfMAGG0gMaoDXIApv-Hu1qE3xTHW0qYM6tSnW03xdBtQ6fFIctVlR6HLQTsHSW15S-cN7K4Vq4vWC1yU25WnKwUJPDE7jo3TAW3JsigOj-C4zULQWdglK4XsSXzsr6AeKRsWLniDaGEET0wiarkDK_Z-1I3OwsEVwDl1XpwGHfntylVpp6A8urVaQrXVRYB8oet6XLwHeyX-wL88EnWCfB5f4BuwRne74oijJHCLw8eP70Ogw6Q2YfLb9TS7LAPMZH2BhlckiEyMcHoIRizGJx5kkk0MILOV8EYsRCAaDpjlmmuMToVBo0poKR-bg2P314dzt-n8jFURH''',
    v2Hash: '''
OM:wh3OKw7CQBSF4TvvO8wMQ5iWBFMBTQg4JAYNBgG4LoMNoZuwETwrqCHhpUgJZmg54jv2F2JBod2xhJI0bwhxNCVaMtUHpB5Acm3CIFEBmcnJWFrag6GQwfgQEuUlm87ohI88OKkFJjyzOe9Kh89PxMst4uMd4XWNh5Y9wnKFsC4QNgUQa2sgadqQZQ3zeY10t_33EMoY41xwLhUi6o6xDk_VF8_V_QelTw''',
  ),
  (
    name: 'a mesh with colors with different color spaces',
    mesh: _colorSpacesOMesh,
    v1Hash: '''
OM:eAFjNGaAgv1bqh66rxOpZrB_1B-j8fVQ__6VM0FgFoM9kAMUOWy_BKoCBuwvX-eyLVh8ncH-DkhDjKb9EwjNYP8RquUm1Ay4lg8wFR9gAgyoDPvnYNtjGFgZlmpn_GeCGWH_CGR51UP7J2dA4Cxco9vklf-BShf8Z5guuvI_IxMzCwMTKwNTBAMfH99_AKdAU24''',
    v2Hash: '''
OM:wmNmlmJiAAN-AU4PDgZVbikxYQamFAYGU1aOpdoZWgFlTYwnGDncJq8EchdwTBddycjEzMLAxMrAxMHHxwcAAyI''',
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

/// Applies [change] to the bytes encoded in [hash].
String _mapHashBytes(String hash, Uint8List Function(Uint8List) change) {
  final bytes = base64Url.decode(base64Url.normalize(hash.substring(3)));
  final changed = base64Url.encode(change(bytes)).replaceAll('=', '');
  return 'OM:$changed';
}

/// [hash] with every bit of its last byte flipped, which is part of the
/// checksum of a zlib stream.
String _corruptLastByte(String hash) {
  return _mapHashBytes(hash, (bytes) => bytes..last ^= 0xFF);
}

/// A large mesh with irregular coordinates, built only out of operations
/// that are exact on every platform.
OMeshRect _largeMesh(int size) {
  return _grid(size, size, offset: (i) => ((i * 37) % 101 - 50) / 1000);
}

/// A short digest of [hash] that is the same on every platform, to pin
/// long hashes.
int _digest(String hash) {
  var digest = 0;
  for (final unit in hash.codeUnits) {
    digest = (digest * 31 + unit) % 1000000007;
  }
  return digest;
}

/// [hash] without the last 4 bytes, the checksum of a zlib stream.
String _truncate(String hash) {
  return _mapHashBytes(
    hash,
    (bytes) => Uint8List.sublistView(bytes, 0, bytes.length - 4),
  );
}

/// [hash] without the byte in the middle of its compressed data.
String _removeMiddleByte(String hash) {
  return _mapHashBytes(hash, (bytes) {
    final middle = bytes.length ~/ 2;
    return Uint8List.fromList([
      ...bytes.take(middle),
      ...bytes.skip(middle + 1),
    ]);
  });
}

/// The neighbor of a positive [value] one unit in the last place above it.
double _nextUp(double value) {
  final data = ByteData(8)..setFloat64(0, value);
  data.setUint32(4, data.getUint32(4) + 1);
  return data.getFloat64(0);
}

/// The v2 data of a regular 2x2 mesh without colors, which is short enough
/// to be listed byte by byte and to build invalid data from.
Uint8List _plainV2Data() {
  return OMeshBinaryFormatCodec.v2.encode(
    _grid(2, 2, colors: List.filled(4, null)),
  );
}

/// The CRC-16/CCITT-FALSE of [bytes], one bit at a time.
int _crc16(List<int> bytes) {
  var crc = 0xFFFF;
  for (final byte in bytes) {
    for (var bit = 7; bit >= 0; bit--) {
      final feedback = ((crc >> 15) & 1) ^ ((byte >> bit) & 1);
      crc = (crc << 1) & 0xFFFF;
      if (feedback == 1) crc ^= 0x1021;
    }
  }
  return crc;
}

/// The bytes encoded in [hash].
Uint8List _hashBytes(String hash) {
  return base64Url.decode(base64Url.normalize(hash.substring(3)));
}

/// A v2 hash of [bytes], the header and the content, with its checksum.
String _v2Hash(List<int> bytes) {
  final crc = _crc16(bytes);
  final encoded = base64Url.encode([...bytes, crc >> 8, crc & 0xFF]);
  return 'OM:${encoded.replaceAll('=', '')}';
}

/// The mesh [hash] decodes to, or null when it throws a [FormatException].
/// Any other error is not caught.
OMeshRect? _tryDecode(String hash) {
  try {
    return getMeshFromHash(hash);
  } on FormatException {
    return null;
  }
}

const _kBase64UrlAlphabet =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

void main() {
  group('v1 hashes', () {
    for (final fixture in _fixtures) {
      test('of ${fixture.name} are generated by the v1 codec', () {
        expect(
          getHashFromMesh(fixture.mesh, codec: OMeshBinaryFormatCodec.v1),
          fixture.v1Hash,
        );
      });

      test('of ${fixture.name} still decode', () {
        expect(getMeshFromHash(fixture.v1Hash), fixture.mesh);
      });
    }

    test('of large meshes are the same on every platform', () {
      final mesh = _largeMesh(15);
      final hash = getHashFromMesh(mesh, codec: OMeshBinaryFormatCodec.v1);

      expect((hash.length, _digest(hash)), (5117, 532470858));
      expect(getMeshFromHash(hash), mesh);
    });

    test('of meshes that compress well are the same on every platform', () {
      // Repetitive data is where a compression level other than 6 writes
      // different bytes. Small, medium and large payloads.
      const pinned = {
        4: (97, 671319480),
        10: (402, 497707824),
        15: (797, 271513937),
      };

      for (final MapEntry(key: size, value: expected) in pinned.entries) {
        final mesh = _grid(
          size,
          size,
          colors: List.filled(size * size, const Color(0xff4693a9)),
        );
        final hash = getHashFromMesh(mesh, codec: OMeshBinaryFormatCodec.v1);

        expect((hash.length, _digest(hash)), expected, reason: 'size $size');
        expect(getMeshFromHash(hash), mesh);
      }
    });

    test('throw a FormatException when corrupted', () {
      for (final fixture in _fixtures) {
        final hash = fixture.v1Hash;

        expect(
          () => getMeshFromHash(_corruptLastByte(hash)),
          throwsFormatException,
        );
        expect(
          () => getMeshFromHash(_truncate(hash)),
          throwsFormatException,
        );
        expect(
          () => getMeshFromHash(_removeMiddleByte(hash)),
          throwsFormatException,
        );
      }
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

    test('of large meshes are the same on every platform', () {
      final mesh = _largeMesh(40);
      final hash = getHashFromMesh(mesh);

      expect((hash.length, _digest(hash)), (33243, 355232422));
      expect(getMeshFromHash(hash), mesh);
    });

    test(
        'of large meshes with decimal coordinates are the same on every '
        'platform', () {
      const size = kMaxOMeshRectDimension;
      final mesh = _grid(size, size).copyWith(
        vertices: [
          for (var i = 0; i < size * size; i++)
            (
              (i % size * 25 + (i * 37) % 11 - 5) / 1000,
              (i ~/ size * 25 - (i * 53) % 13 + 6) / 1000,
            ).v,
        ],
      );
      final hash = getHashFromMesh(mesh);

      // Three fractional digits, not float64.
      expect(OMeshBinaryFormatCodec.v2.encode(mesh)[4], 3);
      expect((hash.length, _digest(hash)), (14427, 899092499));
      expect(getMeshFromHash(hash), mesh);
    });

    test('of meshes that compress well are the same on every platform', () {
      // Repetitive data is where compression levels write different bytes.
      final mesh = _grid(
        15,
        15,
        colors: List.filled(15 * 15, const Color(0xff4693a9)),
      );
      final hash = getHashFromMesh(mesh);

      expect((hash.length, _digest(hash)), (722, 559580250));
      expect(getMeshFromHash(hash), mesh);
    });

    test('are not compressed when that would not make them shorter', () {
      OMeshRect mesh(int size, int seed) {
        return OMeshRect(
          width: size,
          height: size,
          vertices: [
            for (var i = 0; i < size * size; i++)
              (
                (i % size * 50 + (i * 7 + seed) % 9) / 100,
                (i ~/ size * 50 + (i * 5 + seed * 3) % 7) / 100,
              ).v,
          ],
          colors: [
            for (var i = 0; i < size * size; i++)
              Color(0xff000000 | ((i + 1) * (seed + 3) * 0x9e3779) & 0xffffff),
          ],
        );
      }

      // Compressed, this one is 1 byte longer.
      final longer = getHashFromMesh(mesh(2, 0));
      // Compressed, this one is the same length.
      final same = getHashFromMesh(mesh(3, 2));

      expect(
        longer,
        'OM:ggICCQIAAAAAVQoKXV1hBAjapmsItUzWCI_zQQhqmawBAgMEMiY',
      );
      expect(
        same,
        '''
OM:ggMDCQIAAAAAAAQMAAgOBAoABgoCBhACDAwICAkIFxVdCC4qughFQBcIXFV0CHNq0QiKgC4IoZWLCLiq6AjPwEUBAgMEBQYHCAklDw''',
      );
      // The header is the spec version without the compression flag.
      expect(_hashBytes(longer).first, 0x80 | 2);
      expect(_hashBytes(same).first, 0x80 | 2);
      expect(getMeshFromHash(longer), mesh(2, 0));
      expect(getMeshFromHash(same), mesh(3, 2));
    });

    test('end with the CRC-16 of the bytes before it', () {
      expect(_crc16(ascii.encode('123456789')), 0x29B1);

      for (final fixture in _fixtures) {
        final bytes = _hashBytes(fixture.v2Hash);
        final end = bytes.length - 2;

        expect(
          bytes[end] << 8 | bytes[end + 1],
          _crc16(bytes.sublist(0, end)),
          reason: fixture.name,
        );
      }
    });

    test('throw a FormatException for any mistyped character', () {
      for (final fixture in _fixtures) {
        final hash = fixture.v2Hash;

        for (var i = 3; i < hash.length; i++) {
          for (final character in _kBase64UrlAlphabet.split('')) {
            if (character == hash[i]) continue;
            final decoded = _tryDecode(hash.replaceRange(i, i + 1, character));

            // The last character may hold bits that are not part of any
            // byte, so changing it may leave the hash as it was.
            expect(
              decoded,
              i == hash.length - 1 ? anyOf(isNull, fixture.mesh) : isNull,
              reason: '${fixture.name}, $character at $i',
            );
          }
        }
      }
    });

    test('throw a FormatException for any two swapped characters', () {
      for (final fixture in _fixtures) {
        final hash = fixture.v2Hash;

        for (var i = 3; i < hash.length - 1; i++) {
          if (hash[i] == hash[i + 1]) continue;
          final swapped =
              hash.replaceRange(i, i + 2, '${hash[i + 1]}${hash[i]}');

          expect(_tryDecode(swapped), isNull, reason: '${fixture.name}, $i');
        }
      }
    });

    test('throw a FormatException when cut short', () {
      for (final fixture in _fixtures) {
        final hash = fixture.v2Hash;

        for (var length = 3; length < hash.length; length++) {
          expect(
            _tryDecode(hash.substring(0, length)),
            isNull,
            reason: '${fixture.name}, $length characters',
          );
        }
      }
    });

    test('throw a FormatException when empty', () {
      for (final hash in ['', 'OM:']) {
        expect(
          () => getMeshFromHash(hash),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              "O'Mesh hash is empty",
            ),
          ),
        );
      }
    });

    test('throw a FormatException on a part of the prefix', () {
      for (final hash in ['O', 'OM', ':']) {
        expect(() => getMeshFromHash(hash), throwsFormatException);
      }
    });

    test('throw a FormatException when too short for a checksum', () {
      // One byte, and two bytes that are the checksum of no bytes.
      for (final hash in ['OM:gg', 'OM:ggI', 'OM:__8']) {
        expect(
          () => getMeshFromHash(hash),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              "O'Mesh hash is too short",
            ),
          ),
          reason: hash,
        );
      }
    });

    test('throw a FormatException when the content is cut short', () {
      // The content without its spec version byte, behind an uncompressed
      // header.
      final content = _plainV2Data().sublist(1);

      expect(
        getMeshFromHash(_v2Hash([0x80 | 2, ...content])),
        _grid(2, 2, colors: List.filled(4, null)),
      );
      for (var length = 0; length < content.length; length++) {
        expect(
          () => getMeshFromHash(_v2Hash([0x80 | 2, ...content.take(length)])),
          throwsFormatException,
          reason: '$length of ${content.length} bytes',
        );
      }
    });

    test('throw a FormatException on an unknown spec version', () {
      final bytes = _hashBytes(_fixtures.first.v2Hash);
      final content = bytes.sublist(1, bytes.length - 2);

      expect(getMeshFromHash(_v2Hash([0xC2, ...content])), _verySimpleOMesh);
      for (final version in [0, for (var i = 3; i < 64; i++) i]) {
        expect(
          () => getMeshFromHash(_v2Hash([0xC0 | version, ...content])),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              endsWith('format version $version'),
            ),
          ),
        );
      }
    });

    test('start with a byte that no v1 hash starts with', () {
      for (final fixture in _fixtures) {
        expect(
          _hashBytes(fixture.v1Hash).first,
          lessThan(0x80),
          reason: fixture.name,
        );
        expect(
          _hashBytes(fixture.v2Hash).first,
          0x80 | 0x40 | 2,
          reason: fixture.name,
        );
      }
    });

    test('throw a FormatException when the first byte is below 0x80', () {
      final bytes = _hashBytes(_fixtures.first.v2Hash);
      final content = bytes.sublist(1, bytes.length - 2);

      for (var header = 0; header < 0x80; header++) {
        expect(
          () => getMeshFromHash(_v2Hash([header, ...content])),
          throwsFormatException,
          reason: '$header',
        );
      }
    });

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

  group('getMeshFromHash', () {
    test('decodes hashes without the prefix', () {
      for (final fixture in _fixtures) {
        expect(
          getMeshFromHash(fixture.v1Hash.substring(3)),
          fixture.mesh,
          reason: fixture.name,
        );
        expect(
          getMeshFromHash(fixture.v2Hash.substring(3)),
          fixture.mesh,
          reason: fixture.name,
        );
      }
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
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            endsWith('format version 99'),
          ),
        ),
      );
    });

    group('v1', () {
      test('refuses meshes over 15 vertices in a dimension', () {
        expect(
          () => OMeshBinaryFormatCodec.v1.encode(_grid(16, 3)),
          throwsArgumentError,
        );
        expect(
          () => OMeshBinaryFormatCodec.v1.encode(_grid(3, 16)),
          throwsArgumentError,
        );
      });

      test('clamps color components that do not fit in 8 bits', () {
        final mesh = _grid(
          2,
          2,
          colors: const [
            Color.from(
              alpha: 1,
              red: 1.2,
              green: -0.1,
              blue: 0.5,
              colorSpace: ColorSpace.extendedSRGB,
            ),
            null,
            null,
            null,
          ],
        );

        expect(
          _roundTrip(mesh, OMeshBinaryFormatCodec.v1).colors.first,
          const Color(0xffff0080),
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

      test('throws a FormatException on a width or height below 2', () {
        // The spec version, then the width and the height in one byte.
        for (final (size, name) in [
          (0x00, '0x0'),
          (0x12, '1x2'),
          (0x21, '2x1'),
        ]) {
          expect(
            () => OMeshBinaryFormatCodec.v1.decode(
              Uint8List.fromList([1, size]),
            ),
            throwsA(
              isA<FormatException>().having(
                (e) => e.message,
                'message',
                'Invalid mesh size $name',
              ),
            ),
          );
        }
        // A v1 hash of a 0x0 mesh.
        expect(
          () => getMeshFromHash('OM:eAEBBAD7_wEAACAAKAAi'),
          throwsFormatException,
        );
      });

      test('throws a FormatException on NaN, infinite and huge colors', () {
        for (final component in [
          double.nan,
          double.infinity,
          double.negativeInfinity,
          1e308,
        ]) {
          final mesh = _grid(
            2,
            2,
            colors: [
              Color.from(
                alpha: 1,
                red: component,
                green: 0,
                blue: 0,
                colorSpace: ColorSpace.extendedSRGB,
              ),
              null,
              null,
              null,
            ],
          );

          expect(
            () => OMeshBinaryFormatCodec.v1.encode(mesh),
            throwsFormatException,
            reason: '$component',
          );
          expect(
            () => getHashFromMesh(mesh, codec: OMeshBinaryFormatCodec.v1),
            throwsFormatException,
            reason: '$component',
          );
        }
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
        // An extra vertex that has no exact decimal form changes no byte.
        expect(
          OMeshBinaryFormatCodec.v2.encode(
            mesh.copyWith(vertices: [...mesh.vertices, (1 / 3, 0.5).v]),
          ),
          OMeshBinaryFormatCodec.v2.encode(mesh),
        );
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

      test('keeps extended range colors exactly', () {
        const components = [
          [1.5, 4.0, -0.25],
          [12.75, 1000.123456789, 1.0000001],
          [1e308, -1e308, double.maxFinite],
        ];
        final mesh = _grid(
          3,
          2,
          colors: [
            for (final colorSpace in [
              ColorSpace.extendedSRGB,
              ColorSpace.displayP3,
            ])
              for (final [red, green, blue] in components)
                Color.from(
                  alpha: 1,
                  red: red,
                  green: green,
                  blue: blue,
                  colorSpace: colorSpace,
                ),
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

      test('writes a regular mesh without colors field by field', () {
        expect(_plainV2Data(), [
          2, // spec version
          2, 2, // width and height
          9, // flags: lab color space and smooth colors
          0, // number mode: no fractional digits
          0, 0, // no control points
          0, 0, 0, 0, 0, 0, 0, 0, // every vertex is on the regular grid
          0, // empty palette
          0, 0, 0, 0, // no colors
        ]);
      });

      test('writes coordinates with the fewest fractional digits', () {
        const smallest = [
          1.0,
          1e-1,
          1e-2,
          1e-3,
          1e-4,
          1e-5,
          1e-6,
          1e-7,
          1e-8,
          1e-9,
        ];

        for (var digits = 0; digits < smallest.length; digits++) {
          final mesh = _grid(2, 2, colors: List.filled(4, null)).copyWith(
            vertices: [
              (smallest[digits], 0.0).v,
              (1.0, 0.0).v,
              (0.0, 1.0).v,
              (1.0, 1.0).v,
            ],
          );
          final data = OMeshBinaryFormatCodec.v2.encode(mesh);

          // The first x is 1 / 10^digits away from the grid, which is 2 once
          // zigzag encoded.
          expect(
            data,
            _plainV2Data()
              ..[4] = digits
              ..[7] = 2,
            reason: '$digits digits',
          );
          expect(OMeshBinaryFormatCodec.v2.decode(data), mesh);
        }
      });

      test('writes large decimal coordinates as varints over 32 bits', () {
        final mesh = _grid(2, 2, colors: List.filled(4, null)).copyWith(
          vertices: [
            (123456789.125, -98765432.5).v.bezier(
                  north: (-1099511627776.5, 1099511627776.5).v,
                ),
            (1.0, 0.0).v,
            (0.0, 1.0).v,
            (1.0, 1.0).v,
          ],
        );
        final data = OMeshBinaryFormatCodec.v2.encode(mesh);

        expect(data, [
          2, 2, 2, 9,
          3, // number mode: three fractional digits
          1, 0, // the first vertex has a north control point
          138, 234, 200, 233, 151, 7, 231, 154, 135, 238, 223, 5, 241, 241, 200,
          233, 151, 135, 244, 3, 208, 162, 135, 238, 223, 133, 244, 3, //
          0, 0, 0, 0, 0, 0, // the other vertices are on the regular grid
          0, 0, 0, 0, 0,
        ]);
        expect(OMeshBinaryFormatCodec.v2.decode(data), mesh);
        expect(getMeshFromHash(getHashFromMesh(mesh)), mesh);
      });

      test('writes decimals only for coordinates up to 2^50', () {
        OMeshRect withFirst(OVertex vertex) {
          return _grid(2, 2, colors: List.filled(4, null)).copyWith(
            vertices: [vertex, (1.0, 0.0).v, (0.0, 1.0).v, (1.0, 1.0).v],
          );
        }

        // 2^50.
        const limit = 1125899906842624.0;
        final atLimit = withFirst((limit, 0.0).v);
        final overLimit = withFirst((limit + 2, 0.0).v);
        // 2^52 and -2^52, which are 2^53 apart.
        final farApart = withFirst(
          (4 * limit, 0.0).v.bezier(north: (-4 * limit, 0.0).v),
        );

        expect(OMeshBinaryFormatCodec.v2.encode(atLimit)[4], 0);
        expect(OMeshBinaryFormatCodec.v2.encode(overLimit)[4], 0xFF);
        expect(OMeshBinaryFormatCodec.v2.encode(farApart)[4], 0xFF);
        for (final mesh in [atLimit, overLimit, farApart]) {
          expect(_roundTrip(mesh, OMeshBinaryFormatCodec.v2), mesh);
          expect(getMeshFromHash(getHashFromMesh(mesh)), mesh);
        }
      });

      test('keeps coordinates next to a short decimal exactly', () {
        final mesh = _grid(2, 2).copyWith(
          vertices: [
            (0.1 + 0.2, _nextUp(0.5)).v,
            (_nextUp(0.25), -_nextUp(0.125)).v,
            (_nextUp(0.123456789), 1.0).v,
            (1.0, _nextUp(1e-9)).v,
          ],
        );

        expect(0.1 + 0.2, isNot(0.3));
        expect(_roundTrip(mesh, OMeshBinaryFormatCodec.v2), mesh);
        expect(getMeshFromHash(getHashFromMesh(mesh)), mesh);
      });

      test('keeps control points that need more digits than vertices', () {
        final decimal = _grid(2, 2).copyWith(
          vertices: [
            (0.0, 0.0).v.bezier(east: (0.123456, 0.5).v),
            (1.0, 0.0).v,
            (0.0, 1.0).v,
            (1.0, 1.0).v,
          ],
        );
        final float64 = _grid(2, 2).copyWith(
          vertices: [
            (0.0, 0.0).v,
            (1.0, 0.0).v,
            (0.0, 1.0).v,
            (1.0, 1.0).v.bezier(west: (1 / 3, 1.0).v),
          ],
        );

        expect(OMeshBinaryFormatCodec.v2.encode(decimal)[4], 6);
        expect(_roundTrip(decimal, OMeshBinaryFormatCodec.v2), decimal);
        expect(OMeshBinaryFormatCodec.v2.encode(float64)[4], 0xFF);
        expect(_roundTrip(float64, OMeshBinaryFormatCodec.v2), float64);
      });

      test('keeps colors next to an 8-bit color exactly', () {
        final mesh = _grid(
          2,
          2,
          colors: [
            Color.from(alpha: 1, red: _nextUp(128 / 255), green: 0, blue: 1),
            Color.from(alpha: _nextUp(0.5), red: 1, green: 1, blue: 1),
            null,
            null,
          ],
        );

        expect(_roundTrip(mesh, OMeshBinaryFormatCodec.v2), mesh);
      });

      test('writes each color with its shortest exact encoding', () {
        List<int> colorData(Color color) {
          final data = OMeshBinaryFormatCodec.v2.encode(
            _grid(2, 2, colors: [color, null, null, null]),
          );
          // After a palette of one color, before the four color indices.
          expect(data[15], 1);
          return data.sublist(16, data.length - 4);
        }

        List<int> float64(double value) {
          return (ByteData(8)..setFloat64(0, value)).buffer.asUint8List();
        }

        // The header is the encoding in the high 5 bits and the color space
        // in the low 3.
        expect(
          colorData(const Color(0xff4693a9)),
          [1 << 3, 0x46, 0x93, 0xa9],
        );
        expect(
          colorData(const Color(0x80ff8000)),
          [0 << 3, 0xff, 0x80, 0x00, 0x80],
        );
        expect(
          colorData(
            const Color.from(
              alpha: 1,
              red: 1,
              green: 0,
              blue: 0,
              colorSpace: ColorSpace.displayP3,
            ),
          ),
          [1 << 3 | 2, 0xff, 0x00, 0x00],
        );
        // Three fractional digits: 500, 250, 125 and 1000, zigzag encoded.
        expect(
          colorData(
            const Color.from(alpha: 1, red: 0.5, green: 0.25, blue: 0.125),
          ),
          [(3 + 3) << 3, 0xE8, 0x07, 0xF4, 0x03, 0xFA, 0x01, 0xD0, 0x0F],
        );
        // No fractional digits: 2, 0, 0 and 1, zigzag encoded.
        expect(
          colorData(
            const Color.from(
              alpha: 1,
              red: 2,
              green: 0,
              blue: 0,
              colorSpace: ColorSpace.extendedSRGB,
            ),
          ),
          [3 << 3 | 1, 0x04, 0x00, 0x00, 0x02],
        );
        // Nine fractional digits, the most: 123456789, 0, 0 and 10^9.
        expect(
          colorData(
            const Color.from(alpha: 1, red: 0.123456789, green: 0, blue: 0),
          ),
          [
            (3 + 9) << 3,
            0xAA, 0xB4, 0xDE, 0x75, //
            0x00, 0x00,
            0x80, 0xA8, 0xD6, 0xB9, 0x07,
          ],
        );
        expect(
          colorData(
            const Color.from(
              alpha: 1,
              red: 1 / 7,
              green: 0,
              blue: 0,
              colorSpace: ColorSpace.extendedSRGB,
            ),
          ),
          [
            2 << 3 | 1,
            ...float64(1 / 7),
            ...float64(0),
            ...float64(0),
            ...float64(1),
          ],
        );
      });

      test('keeps every combination of metadata', () {
        const color = Color(0xff4693a9);

        for (final colorSpace in OMeshColorSpace.values) {
          for (final smoothColors in [false, true]) {
            for (final fallbackColor in [null, color]) {
              for (final backgroundColor in [null, _displayP3Color]) {
                final plain = _grid(2, 2);
                final mesh = OMeshRect(
                  width: 2,
                  height: 2,
                  vertices: plain.vertices,
                  colors: plain.colors,
                  colorSpace: colorSpace,
                  smoothColors: smoothColors,
                  fallbackColor: fallbackColor,
                  backgroundColor: backgroundColor,
                );
                final data = OMeshBinaryFormatCodec.v2.encode(mesh);

                expect(
                  data[3],
                  colorSpace.index |
                      (smoothColors ? 0x08 : 0) |
                      (fallbackColor != null ? 0x10 : 0) |
                      (backgroundColor != null ? 0x20 : 0),
                );
                expect(OMeshBinaryFormatCodec.v2.decode(data), mesh);
              }
            }
          }
        }
      });

      test('throws a FormatException on invalid fields', () {
        Uint8List withByte(int index, int value) {
          return _plainV2Data()..[index] = value;
        }

        // The data up to the palette, then [palette] and the color indices.
        Uint8List withPalette(List<int> palette, {int firstIndex = 0}) {
          return Uint8List.fromList(
            [..._plainV2Data().take(15), ...palette, firstIndex, 0, 0, 0],
          );
        }

        // Invalid data, by the message of the exception it throws.
        final invalid = {
          'Invalid mesh size 1x2': withByte(1, 1),
          'Invalid mesh size 2x1': withByte(2, 1),
          'Unknown mesh color space 3': withByte(3, 0x08 | 3),
          'Unknown mesh color space 4': withByte(3, 0x08 | 4),
          'Unknown mesh color space 7': withByte(3, 0x08 | 7),
          'Unknown number mode 10': withByte(4, 10),
          'Unknown number mode 254': withByte(4, 0xFE),
          'Color index 1 out of range': withByte(16, 1),
          'Color index 2 out of range':
              withPalette([1, 1 << 3, 0, 0, 0], firstIndex: 2),
          'Unknown color encoding 13': withPalette([1, 13 << 3, 0, 0, 0, 0]),
          'Unknown color encoding 16': withPalette([1, 16 << 3, 0, 0, 0, 0]),
          'Unknown color encoding 31': withPalette([1, 31 << 3, 0, 0, 0, 0]),
          'Unknown color space 3': withPalette([1, 1 << 3 | 3, 0, 0, 0]),
          'Unknown color space 4': withPalette([1, 1 << 3 | 4, 0, 0, 0]),
          'Unknown color space 7': withPalette([1, 1 << 3 | 7, 0, 0, 0]),
          'varint is too long': withPalette(
            [0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00],
          ),
        };

        expect(
          OMeshBinaryFormatCodec.v2.decode(
            withPalette([1, 1 << 3, 0, 0, 0], firstIndex: 1),
          ),
          _grid(2, 2, colors: const [Color(0xff000000), null, null, null]),
        );
        for (final MapEntry(key: message, value: data) in invalid.entries) {
          expect(
            () => OMeshBinaryFormatCodec.v2.decode(data),
            throwsA(
              isA<FormatException>().having(
                (e) => e.message,
                'message',
                message,
              ),
            ),
          );
        }
      });

      test('leaves the maximum size of a mesh to OMeshRect', () {
        // A regular mesh without colors, as listed field by field above.
        Uint8List data(int width, int height) {
          final count = width * height;
          return Uint8List.fromList([
            2, width, height, 9, 0, //
            ...List.filled((count + 1) ~/ 2, 0),
            ...List.filled(count * 2, 0),
            0,
            ...List.filled(count, 0),
          ]);
        }

        const max = kMaxOMeshRectDimension;

        final largest = OMeshBinaryFormatCodec.v2.decode(data(max, 2));

        expect((largest.width, largest.height), (max, 2));
        expect(largest.vertices.last, (1.0, 1.0).v);
        // The assert of the OMeshRect constructor.
        expect(
          () => OMeshBinaryFormatCodec.v2.decode(data(max + 1, 2)),
          throwsAssertionError,
        );
        expect(
          () => OMeshBinaryFormatCodec.v2.decode(data(255, 255)),
          throwsAssertionError,
        );
      });

      test('reads varints up to 2^53 - 1 and throws on larger ones', () {
        // The data with [varint] as the x coordinate of the first vertex.
        Uint8List withFirstX(List<int> varint) {
          final data = _plainV2Data();
          return Uint8List.fromList(
            [...data.take(7), ...varint, ...data.skip(8)],
          );
        }

        final tooLarge = throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'varint is too large',
          ),
        );

        // 2^53 - 1, which is -2^52 once zigzag decoded.
        expect(
          OMeshBinaryFormatCodec.v2
              .decode(
                withFirstX([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F]),
              )
              .vertices
              .first,
          (-4503599627370496.0, 0.0).v,
        );
        // 2^53.
        expect(
          () => OMeshBinaryFormatCodec.v2.decode(
            withFirstX([0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x10]),
          ),
          tooLarge,
        );
        // 2^56 - 1, the largest value that fits in 8 bytes.
        expect(
          () => OMeshBinaryFormatCodec.v2.decode(
            withFirstX([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F]),
          ),
          tooLarge,
        );
      });

      test('throws on a palette longer than the vertex count', () {
        final bytes = OMeshBinaryFormatCodec.v2.encode(
          _grid(2, 2, colors: List.filled(4, null)),
        );
        // Without colors, the data ends with an empty palette and one color
        // index per vertex.
        expect(bytes.sublist(bytes.length - 5), [0, 0, 0, 0, 0]);
        final beforePalette = bytes.sublist(0, bytes.length - 5);

        for (final paletteLength in [
          [5],
          [0xFF, 0xFF, 0xFF, 0xFF, 0x07],
        ]) {
          final data = Uint8List.fromList(
            [...beforePalette, ...paletteLength, 0, 0, 0, 0],
          );

          expect(
            () => OMeshBinaryFormatCodec.v2.decode(data),
            throwsFormatException,
          );
        }
      });

      test('throws a FormatException on truncated data', () {
        for (final codec in [
          OMeshBinaryFormatCodec.v1,
          OMeshBinaryFormatCodec.v2,
        ]) {
          final bytes = codec.encode(_complexOMesh);

          for (var length = 0; length < bytes.length; length++) {
            expect(
              () => codec.decode(Uint8List.sublistView(bytes, 0, length)),
              throwsA(
                isA<FormatException>().having(
                  (e) => e.message,
                  'message',
                  startsWith("O'Mesh data is truncated or invalid: "),
                ),
              ),
              reason: '$length of ${bytes.length} bytes',
            );
          }
        }
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

      test('rounds to the given decimal places', () {
        final mesh = _grid(2, 2).copyWith(
          vertices: [
            (0.26, 0.0).v,
            (1.0, 0.0).v,
            (0.0, 1.0).v,
            (1.0, 1.0).v,
          ],
        );

        for (final (decimalPlaces, x) in [(0, 0.0), (1, 0.3), (2, 0.26)]) {
          final codec =
              OMeshBinaryFormatCodec.v2Rounded(decimalPlaces: decimalPlaces);

          expect(codec.encode(mesh)[4], decimalPlaces);
          expect(_roundTrip(mesh, codec).vertices.first, (x, 0.0).v);
        }
      });

      test('throws an ArgumentError for decimal places out of range', () {
        final exact = OMeshBinaryFormatCodec.v2.encode(_verySimpleOMesh);

        for (final decimalPlaces in [0, 9]) {
          final codec =
              OMeshBinaryFormatCodec.v2Rounded(decimalPlaces: decimalPlaces);

          expect(codec.encode(_verySimpleOMesh), exact);
        }
        for (final decimalPlaces in [-1, 10]) {
          final codec =
              OMeshBinaryFormatCodec.v2Rounded(decimalPlaces: decimalPlaces);

          expect(() => codec.encode(_verySimpleOMesh), throwsArgumentError);
          expect(
            () => getHashFromMesh(_verySimpleOMesh, codec: codec),
            throwsArgumentError,
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
