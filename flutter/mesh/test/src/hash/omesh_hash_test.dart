import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/hash.dart';
import 'package:mesh/mesh.dart';

/// A regular [width] x [height] mesh with coordinates offset by [offset]
/// and a different color on every vertex, unless [color] is given.
OMeshRect _grid(
  int width,
  int height, {
  double Function(int index)? offset,
  Color? color,
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
    colors: [
      for (var i = 0; i < count; i++)
        color ?? Color(0xff000000 | (i * 0x9e3779) & 0xffffff),
    ],
  );
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

void main() {
  test('encodes and decodes a very simple mesh', () {
    final verySimpleOMesh = OMeshRect(
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

    final hash = getHashFromMesh(verySimpleOMesh);

    expect(
      hash,
      equals(
        '''
OM:eAFjVGJAB_YfMITQJGAMuAAjg9vklf-BFKMBAMdnB5Q''',
      ),
    );

    final mesh = getMeshFromHash(hash);

    expect(mesh, verySimpleOMesh);
  });

  test('encodes and decodes a simple mesh', () {
    final simpleOMesh = OMeshRect(
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

    final hash = getHashFromMesh(simpleOMesh);

    expect(
      hash,
      equals(
        '''
OM:eAFjNGaAgv1bqh66rxOpZrB_1B-j8fVQ__6VM0FgFoM9kAMUOWy_BKoCBuwvX-eyLVh8ncH-DkhDjKb9EwjNYP8RquUm1Ay4lg8wFR9gAgyoDPvnYNtjGFgZlmpn_Gdwm7zyP5C14D_Di1tX_jNMF135n5GJiZmFiZWJyQAAOTlFhA''',
      ),
    );

    final mesh = getMeshFromHash(hash);

    expect(mesh, simpleOMesh);
  });

  test('encodes and decodes a custom mesh', () {
    final meshRect = OMeshRect(
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

    final hash = getHashFromMesh(meshRect);

    expect(
      hash,
      equals(
        '''
OM:eAFdUS1Mw0AUfqPlp5A0ExMoSFB49PJJsAMEAoFCFzskmcYgoALBZkCQQBBzDWAQLGEsZGMkS8vYwjLESgL2uOu7a8Je0nsv776fd6-ZzeBqWFqoFr6CSjFavcztE-oyFaM1c0EIy83ZvFcJbgxiMI6IdcMggiMu0M57imwFp9WCAqOxkgTudX5TCsOS8UCHcQ4ilsSTvmgl_XW0fu4Ot5d_8c7K6LLQHHqJ0CLazEQ_l8yAj0cVtdQh4qHxSUnghXk2BicqfITaYfQfQCbQS5z3CK-aoWew8SyJko2usio3Eeqh-_wqSk1TidFYIzCLiQ2ixoXZsfwdmhKzuxTVL_vmlUhR8wLO5NDtxZkgQfPq2JDH9a6ghtiRlfcg6PjgXNBSNiuo4_siM2HZk5Y1ZfE3PeM4zha5riv-ADA18mc''',
      ),
    );

    final mesh = getMeshFromHash(hash);

    expect(mesh, meshRect);
  });

  test('encodes and decodes a complex mesh', () {
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

    final hash = getHashFromMesh(complexOMesh);

    expect(
      hash,
      equals(
        '''
OM:eAFlkD9MwlAQxq9QFStssOKKI3EVbwQXE1AnnZ0xbrrKzOKig4ssDpK4MZg0gbgYNaJBYzTEWosYQHFAjEt9f-49Bm_4aMvdd7_7jBW7XMl2CvGKvbPlpMvRbcAr-nDCNdsFfBbvOfs0MagW12YA38pR3mwf7fHaB-zLWXuXPOySfMAGG0gMaoDXIApv-Hu1qE3xTHW0qYM6tSnW03xdBtQ6fFIctVlR6HLQTsHSW15S-cN7K4Vq4vWC1yU25WnKwUJPDE7jo3TAW3JsigOj-C4zULQWdglK4XsSXzsr6AeKRsWLniDaGEET0wiarkDK_Z-1I3OwsEVwDl1XpwGHfntylVpp6A8urVaQrXVRYB8oet6XLwHeyX-wL88EnWCfB5f4BuwRne74oijJHCLw8eP70Ogw6Q2YfLb9TS7LAPMZH2BhlckiEyMcHoIRizGJx5kkk0MILOV8EYsRCAaDpjlmmuMToVBo0poKR-bg2P314dzt-n8jFURH''',
      ),
    );

    final mesh = getMeshFromHash(hash);

    expect(mesh, complexOMesh);
  });

  test('encodes and decodes a mesh with colors with different color spaces',
      () {
    final meshRect = OMeshRect(
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
        Color.from(
          alpha: 1,
          red: 0.4,
          green: 0.59,
          blue: 0.65,
          colorSpace: ColorSpace.displayP3,
        ),
        Color(0xff4693a9), // Row 1

        Color(0xffa52ba0),
        null,
        Color.from(
          alpha: 1,
          red: 0.4,
          green: 0.59,
          blue: 0.65,
          colorSpace: ColorSpace.displayP3,
        ), // Row 2

        Color(0xff9715a9),
        null,
        Color.from(
          alpha: 1,
          red: 0.4,
          green: 0.59,
          blue: 0.65,
          colorSpace: ColorSpace.displayP3,
        ), // Row 3
      ],
    );

    final hash = getHashFromMesh(meshRect);

    expect(
      hash,
      equals(
        '''
OM:eAFjNGaAgv1bqh66rxOpZrB_1B-j8fVQ__6VM0FgFoM9kAMUOWy_BKoCBuwvX-eyLVh8ncH-DkhDjKb9EwjNYP8RquUm1Ay4lg8wFR9gAgyoDPvnYNtjGFgZlmpn_GeCGWH_CGR51UP7J2dA4Cxco9vklf-BShf8Z5guuvI_IxMzCwMTKwNTBAMfH99_AKdAU24''',
      ),
    );

    final mesh = getMeshFromHash(hash);

    expect(mesh, meshRect);
  });

  test('encodes a large mesh to the same hash on every platform', () {
    final mesh = _largeMesh(15);
    final hash = getHashFromMesh(mesh);

    expect((hash.length, _digest(hash)), (5117, 532470858));
    expect(getMeshFromHash(hash), mesh);
  });

  test('encodes meshes that compress well to the same hash on every platform',
      () {
    // Repetitive data is where a compression level other than 6 writes
    // different bytes. Small, medium and large payloads.
    const pinned = {
      4: (97, 671319480),
      10: (402, 497707824),
      15: (797, 271513937),
    };

    for (final MapEntry(key: size, value: expected) in pinned.entries) {
      final mesh = _grid(size, size, color: const Color(0xff4693a9));
      final hash = getHashFromMesh(mesh);

      expect((hash.length, _digest(hash)), expected, reason: 'size $size');
      expect(getMeshFromHash(hash), mesh);
    }
  });

  test('throws a FormatException when the hash is damaged', () {
    final hashes = [
      getHashFromMesh(_grid(2, 2)),
      getHashFromMesh(_grid(4, 4, color: const Color(0xff4693a9))),
      getHashFromMesh(_largeMesh(15)),
    ];

    for (final hash in hashes) {
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
}
