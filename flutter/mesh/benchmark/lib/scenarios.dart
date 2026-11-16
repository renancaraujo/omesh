import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mesh/mesh.dart';
import 'package:mesh_benchmark/meshes.dart';

class CustomAnimationScenario extends StatefulWidget {
  const CustomAnimationScenario({
    required this.meshAt,
    this.tessellation = 12,
    super.key,
  });

  final OMeshRect Function(double t) meshAt;
  final int tessellation;

  @override
  State<CustomAnimationScenario> createState() =>
      _CustomAnimationScenarioState();
}

class _CustomAnimationScenarioState extends State<CustomAnimationScenario>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => OMeshGradient(
        mesh: widget.meshAt(_controller.value),
        tessellation: widget.tessellation,
      ),
    );
  }
}

class ImplicitAnimationScenario extends StatefulWidget {
  const ImplicitAnimationScenario({
    this.period = const Duration(milliseconds: 800),
    super.key,
  });

  final Duration period;

  @override
  State<ImplicitAnimationScenario> createState() =>
      _ImplicitAnimationScenarioState();
}

class _ImplicitAnimationScenarioState extends State<ImplicitAnimationScenario> {
  late final Timer _timer;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.period, (_) {
      setState(() => _flipped = !_flipped);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOMeshGradient(
      mesh: denseMesh(_flipped ? 0.5 : 0, size: 6),
      duration: widget.period,
      tessellation: 12,
    );
  }
}
