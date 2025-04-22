import 'dart:ui';

import 'package:example/examples/advanced.dart';
import 'package:example/examples/basic.dart';
import 'package:example/examples/custom_animation.dart';
import 'package:example/examples/instrinsic_animation.dart';
import 'package:example/examples/masking.dart';
import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Main(), backgroundColor: Colors.black),
    ),
  );
}

enum Example {
  basic(
    view: BasicUsage(),
    title: 'Basic Usage',
    description: 'A simple usage of a 3x3 mesh with colors in each vertex',
    code: BasicUsage.code,
  ),
  advanced(
    view: AdvancedUsage(),
    title: 'Advanced usage',
    description: '''
More advanced example with different colors in each vertex, bezier vertices and color inference''',
    code: AdvancedUsage.code,
  ),
  intrinsicAnimation(
    view: InstrinsicAnimation(),
    title: 'Intrinsic animation',
    description: 'An example to illustrate animation on state change',
    code: InstrinsicAnimation.code,
  ),
  customAnimation(
    view: CustomAnimation(),
    title: 'Custom animation',
    description: '''
An example to illustrate animation from an animation controller.''',
    code: CustomAnimation.code,
  ),
  masking(
    view: MaskingUsage(),
    title: 'Masking Usage',
    description: 'A simple example how to apply WidgetMask to OMeshGradient',
    code: MaskingUsage.code,
  ),
  ;

  const Example({
    required this.title,
    required this.view,
    required this.description,
    required this.code,
  });

  final String title;
  final Widget view;
  final String description;
  final String code;
}

class Main extends StatefulWidget {
  const Main({
    super.key,
  });

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  Example exampleScreen = Example.values.first;

  @override
  Widget build(BuildContext context) {
    return Box(
      style: Style(
        $box.color.black(),
      ),
      child: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            child: ExampleView(
              key: ValueKey(exampleScreen),
              example: exampleScreen,
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Box(
                style: Style(
                  $box.alignment.center(),
                  $box.width(145),
                  $box.maxHeight(180),
                  $box.borderRadius.topRight(16),
                  $box.borderRadius.bottomRight(16),
                  $box.padding(8),
                  $box.border(
                    color: Colors.white.withAlpha((255 * 0.2).floor()),
                    width: 1,
                    style: BorderStyle.solid,
                    strokeAlign: 2,
                  ),
                  $text.style.color.white(),
                  $box.decoration.gradient.linear(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.black, Colors.transparent],
                  ),
                  $box.clipBehavior.hardEdge(),
                ),
                child: Stack(
                  children: [
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: const SizedBox.expand(),
                    ),
                    Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final i in Example.values)
                            ExampleButton(
                              example: i,
                              selected: exampleScreen == i,
                              onSelect: (e) => setState(() {
                                exampleScreen = e;
                              }),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExampleButton extends StatelessWidget {
  const ExampleButton({
    required this.example,
    required this.onSelect,
    required this.selected,
    super.key,
  });

  final Example example;
  final ValueChanged<Example> onSelect;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: PressableBox(
        style: Style(
          $box.padding.vertical(4),
          $box.padding.horizontal(8),
          $box.width.infinity(),
          $box.margin.vertical(2),
          $text.style.color.white(),
          $text.style.fontSize(12),
          $text.style.fontWeight(FontWeight.w400),
          $box.borderRadius.all(12),
          $with.scale(1),
          $box.color(
            selected
                ? Colors.white.withAlpha((255 * 0.1).floor())
                : Colors.transparent,
          ),
          $on.hover(
            $box.color.white.withOpacity(0.4),
          ),
          $on.press(
            $with.scale(0.95),
          ),
        ).animate(duration: const Duration(milliseconds: 100)),
        onPress: () => onSelect(example),
        child: StyledText(
          example.title,
        ),
      ),
    );
  }
}

class ExampleView extends StatelessWidget {
  const ExampleView({
    required this.example,
    super.key,
  });

  final Example example;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Box(
        style: Style(
          $box.alignment.topCenter(),
          $box.maxWidth(800),
          $box.padding(10),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Box(
                    style: Style(
                      $box.padding(20, 10, 0),
                      $text.style(
                        color: Colors.white.withAlpha((255 * 0.7).floor()),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    child: const StyledText("O'Mesh Flutter examples"),
                  ),
                  const SizedBox(width: 10),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: PressableBox(
                      style: Style(
                        $box.padding(20, 10, 0),
                        $text.style(
                          color: Colors.white.withAlpha((255 * 0.7).floor()),
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                        $on.hover(
                          $text.style.color.white(),
                        ),
                      ),
                      onPress: () async {
                        await launchUrl(
                          Uri.parse('https://github.com/renancaraujo/omesh'),
                        );
                      },
                      child: const StyledText('Open in Github'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: PressableBox(
                      style: Style(
                        $box.padding(20, 10, 0),
                        $text.style(
                          color: Colors.white.withAlpha((255 * 0.7).floor()),
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                        $on.hover(
                          $text.style.color.white(),
                        ),
                      ),
                      onPress: () async {
                        await launchUrl(
                          Uri.parse('https://omesh-playground.renan.gg/'),
                        );
                      },
                      child: const StyledText('Open playground'),
                    ),
                  ),
                ],
              ),
              Box(
                style: Style(
                  $box.padding(0, 10, 30),
                  $text.style(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: StyledText(example.title),
              ),
              Box(
                style: Style(
                  $box.borderRadius.all(12),
                  $box.clipBehavior.antiAlias(),
                  $box.border(
                    color: Colors.white.withAlpha((255 * 0.6).floor()),
                    width: 1,
                    style: BorderStyle.solid,
                    strokeAlign: -1,
                  ),
                ),
                child: example.view,
              ),
              Box(
                style: Style(
                  $box.padding(20, 10, 0),
                  $text.style(
                    color: Colors.white.withAlpha((255 * 0.9).floor()),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                child: StyledText(example.description),
              ),
              Box(
                style: Style(
                  $box.margin(20, 0),
                  $box.padding(20, 10, 0),
                  $text.style(
                    color: Colors.white.withAlpha((255 * 0.9).floor()),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                child: const StyledText('Code:'),
              ),
              Box(
                style: Style(
                  $box.padding(32, 22),
                  $box.borderRadius.all(12),
                  $box.border(
                    color: Colors.white.withAlpha((255 * 0.6).floor()),
                    width: 1,
                    style: BorderStyle.solid,
                    strokeAlign: -1,
                  ),
                ),
                child: CodeBlock(
                  code: example.code,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CodeBlock extends StatefulWidget {
  const CodeBlock({required this.code, super.key});

  final String code;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  static final Future<HighlighterTheme> theme = (() async {
    await Highlighter.initialize(['dart']);
    return HighlighterTheme.loadDarkTheme();
  })();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HighlighterTheme>(
      future: theme,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final hl = Highlighter(
            language: 'dart',
            theme: snapshot.data!,
          );
          final highlightedCode = hl.highlight(widget.code);
          return SelectionArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text.rich(highlightedCode),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
