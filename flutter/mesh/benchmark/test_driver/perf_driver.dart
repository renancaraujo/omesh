import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  final out = Platform.environment['BENCH_OUT'] ?? 'build/benchmark';
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      final results = Map<String, Object?>.of(
        data['results']! as Map<String, Object?>,
      );

      final images = results.remove('images') as Map<String, Object?>?;
      if (images != null) {
        final dir = Directory('$out/images')..createSync(recursive: true);
        for (final MapEntry(:key, :value) in images.entries) {
          File('${dir.path}/$key.rgba')
              .writeAsBytesSync(base64Decode(value! as String));
        }
      }

      Directory(out).createSync(recursive: true);
      File('$out/results.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(results),
      );
      stdout.writeln('Wrote $out/results.json');
    },
  );
}
