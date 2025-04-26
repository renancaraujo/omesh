import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/hash.dart';
import 'package:mesh/mesh.dart';

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
OM:eJxjVGJAB_YfMITQJGAMuAAjg9vklf8ZGBkYmRkAzqEHZw''',
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
OM:eJxjNGaAgv1bqh66rxOpZrB_1B-j8fVQ__6VM0FgFoP910MgkcP2S6AqYMD-8nUu24LF1xns74A0xGjaP4HQDPYfoVpuQs2Aa_kAU_EBJsCAyrB_DrY9hoGVYal2xn8Gt8kr_zMs1V7wn-HFrSv_GaaLrvzPyMTEzMLEysTEzAAAfmNFVw''',
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
        Color(0xff9883a9), Color(0xffde9a9a), Color(0xffde9a9a),
        Color(0xffde9a9a), Color(0xffde9a9a), // Row 4
      ],
    );

    final hash = getHashFromMesh(meshRect);

    expect(
      hash,
      equals(
        '''
OM:eJxdUD1MwkAUfrVFqyadOjjpyu5MvhFX1JHByRlXHA0zi4N2cBAWHUg0DmyNuDhIohIDYkJaEQLBoTXB9cz13TWRL2nv8u77ee8Z-_7NrLLZLHz79XKYb7jHhJd8wy2HO_qBENS6a7lS3b_TjOkiI1YFzfBP-YJ-riTFpn_RLEgyOtsJ8KDOD-kwq-gMDJi3ipAt8aweekl9F715q1rM_uKTnTFko3WMEqMt9FmJsZv0gK8niXaaEHLTmFACvLHOwvRcwkOgEqL_BNLAKEk-IrwrherBwmu1mJ23qhjKqFoXgWp6zFNRGppaRAsFXy8m1ow2X_SOCYGSxJxOmKjJfnglhEhPwCfZdH99KUjQhvztCRK3h4I64kCQKD0KOju5EjTwPGEsmVbGNJdN_lZs27YzBjmOI_4AV4_w0A''',
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
OM:eJxlkDFMwkAUhl9pVaywwYorjsQZ3wguJqBOMDtj3HSVmcVFBxdZHCRxYzC5BOJixIgGjdEQawUxgOKANS5n7u5dGXzDtdf-73_f-411Vqlm-sVYle1uO6lKZAfwij6cijMzAHyW9yw7i49rpfwC4FslIsTseF_UAeBI9bI98mBl9YKtWikfH9cBr0EW3oh7reSb4rlW9EhBSt8UmykxLg16HD5pjvqiLHQFaL9o-1NekoWjezuJuuP1UlQD22o17WBjRzbO46NywFtybMsFI_iuMtC0Ng4ISuN3FL7vrKEfKBodL3Yk0eYEmpgm0LQFUu7_rB2Vg41dgnNouyY1OPQcqlF6pOF_cGm0huxuyAJ2qOmFrlAGvFN_cKTWBD_BkQgu_g04JDpf8UVRkjmE4eOHc2j1OYfhmHP47PEtcawBLKU5wHKOA6zkOBihkAdGNOqBEYt5YCQSHgRWs1zGYgRM07SsKcuangkGg7P2XChsmnDi_nK4cAf8D12wRBE''',
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
      colors: [
        const Color(0xffa52b68),
        const Color(0xff4693a9).withValues(
          colorSpace: ColorSpace.displayP3,
        ),
        const Color(0xff4693a9), // Row 1

        const Color(0xffa52ba0),
        null,
        const Color(0xff4693a9).withValues(
          colorSpace: ColorSpace.displayP3,
        ), // Row 2

        const Color(0xff9715a9),
        null,
        const Color(0xff4693a9).withValues(
          colorSpace: ColorSpace.displayP3,
        ), // Row 3
      ],
    );

    final hash = getHashFromMesh(meshRect);

    expect(
      hash,
      equals(
        '''
OM:eJxjNGaAgv1bqh66rxOpZrB_1B-j8fVQ__6VM0FgFoP910MgkcP2S6AqYMD-8nUu24LF1xns74A0xGjaP4HQDPYfoVpuQs2Aa_kAU_EBJsCAyrB_DrY9hoGVYal2xn8m-5u7Atz-_vpu_-iU9WdPjjf2T9b7Cm64tgqu0W3yyv8MS7UX_GeYLrryPyMTMwsDEysDEysjAx8f338A1ddSJw''',
      ),
    );

    final mesh = getMeshFromHash(hash);

    expect(mesh, meshRect);
  });
}
