import 'package:flutter/material.dart';

/// Fades + slides its children up in sequence on mount, giving each screen a
/// polished staggered entrance without per-screen boilerplate.
class StaggeredColumn extends StatefulWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final Duration stagger;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.stagger = const Duration(milliseconds: 70),
  });

  @override
  State<StaggeredColumn> createState() => _StaggeredColumnState();
}

class _StaggeredColumnState extends State<StaggeredColumn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          AnimatedSlide(
            duration: Duration(milliseconds: 400 + i * 40),
            curve: Curves.easeOutCubic,
            offset: _visible ? Offset.zero : const Offset(0, 0.12),
            child: AnimatedOpacity(
              duration: widget.stagger * (i + 4),
              opacity: _visible ? 1 : 0,
              child: widget.children[i],
            ),
          ),
      ],
    );
  }
}
