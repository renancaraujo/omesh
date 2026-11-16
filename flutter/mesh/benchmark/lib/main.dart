import 'package:flutter/widgets.dart';
import 'package:mesh_benchmark/meshes.dart';
import 'package:mesh_benchmark/scenarios.dart';

void main() => runApp(const BenchmarkApp());

class BenchmarkApp extends StatefulWidget {
  const BenchmarkApp({super.key});

  @override
  State<BenchmarkApp> createState() => _BenchmarkAppState();
}

class _BenchmarkAppState extends State<BenchmarkApp> {
  static final _scenarios = <String, Widget>{
    'example 3x4': const CustomAnimationScenario(meshAt: exampleMesh),
    'dense 10x10': const CustomAnimationScenario(
      meshAt: denseMesh,
      tessellation: 16,
    ),
    'implicit': const ImplicitAnimationScenario(),
  };

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final name = _scenarios.keys.elementAt(_index);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onTap: () => setState(
          () => _index = (_index + 1) % _scenarios.length,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            KeyedSubtree(key: ValueKey(name), child: _scenarios[name]!),
            Positioned(
              left: 16,
              top: 16,
              child: Text(name, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
