import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('usage: dart tool/compare.dart label=dir label=dir...');
    exit(64);
  }
  final runs = [
    for (final arg in args)
      () {
        final [label, dir] = arg.split('=');
        final json = jsonDecode(File('$dir/results.json').readAsStringSync());
        return (label: label, dir: dir, results: json as Map<String, dynamic>);
      }(),
  ];

  _table(runs, 'paint', 'UI thread: `OMeshRectPaint.paint` per frame', [
    ('median_us', 'median µs'),
    ('p90_us', 'p90 µs'),
    ('rss_growth_mb', 'RSS growth MB'),
  ]);
  _table(runs, 'raster', 'Raster + GPU: one 3840×2160 frame', [
    ('net_median_ms', 'median ms'),
  ]);
  _table(runs, 'frames', 'Animated widgets on screen (FrameTiming)', [
    ('build.median_ms', 'build median ms'),
    ('build.p90_ms', 'build p90 ms'),
    ('raster.median_ms', 'raster median ms'),
    ('raster.p90_ms', 'raster p90 ms'),
  ]);
  _table(runs, 'hash', '`OMeshRect.fromHash`', [('median_us', 'median µs')]);
  _images(runs);
}

typedef _Run = ({String label, String dir, Map<String, dynamic> results});

void _table(
  List<_Run> runs,
  String group,
  String title,
  List<(String, String)> metrics,
) {
  final base = runs.first.results[group] as Map<String, dynamic>?;
  if (base == null) return;
  stdout
    ..writeln('\n### $title\n')
    ..writeln(
      '| case | metric | ${runs.map((r) => r.label).join(' | ')} |',
    )
    ..writeln('|---|---|${'---|' * runs.length}');
  for (final name in base.keys) {
    for (final (key, label) in metrics) {
      final values = [
        for (final run in runs)
          _lookup((run.results[group] as Map<String, dynamic>?)?[name], key),
      ];
      if (values.first == null) continue;
      final cells = [
        for (var i = 0; i < values.length; i++)
          _cell(values[i], i == 0 ? null : values.first),
      ];
      stdout.writeln('| $name | $label | ${cells.join(' | ')} |');
    }
  }
}

num? _lookup(Object? json, String path) {
  var node = json;
  for (final part in path.split('.')) {
    node = node is Map<String, dynamic> ? node[part] : null;
  }
  return node as num?;
}

String _cell(num? value, num? base) {
  if (value == null) return '–';
  final text = value.toStringAsFixed(value.abs() >= 100 ? 0 : 2);
  if (base == null || base == 0) return text;
  final change = (value - base) / base * 100;
  final sign = change > 0 ? '+' : '';
  return '$text (${'$sign${change.toStringAsFixed(0)}'}%)';
}

void _images(List<_Run> runs) {
  final baseDir = Directory('${runs.first.dir}/images');
  if (!baseDir.existsSync() || runs.length < 2) return;
  stdout
    ..writeln('\n### Output vs ${runs.first.label} (RGBA bytes)\n')
    ..writeln('| image | run | max channel diff | pixels differing > 2 |')
    ..writeln('|---|---|---|---|');
  final files = baseDir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceAll('.rgba', '');
    final a = file.readAsBytesSync();
    for (final run in runs.skip(1)) {
      final other = File('${run.dir}/images/$name.rgba');
      if (!other.existsSync()) continue;
      final b = other.readAsBytesSync();
      var maxDiff = 0;
      var differing = 0;
      for (var p = 0; p + 3 < math.min(a.length, b.length); p += 4) {
        var pixelMax = 0;
        for (var c = 0; c < 4; c++) {
          pixelMax = math.max(pixelMax, (a[p + c] - b[p + c]).abs());
        }
        maxDiff = math.max(maxDiff, pixelMax);
        if (pixelMax > 2) differing++;
      }
      final pct = differing / (a.length / 4) * 100;
      stdout.writeln(
        '| $name | ${run.label} | $maxDiff | ${pct.toStringAsFixed(2)}% |',
      );
    }
  }
}
