import 'package:flutter/material.dart';

class ShimmerListSkeleton extends StatelessWidget {
  const ShimmerListSkeleton({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 20),
    this.asSliver = false,
  });

  final int itemCount;
  final EdgeInsets padding;
  final bool asSliver;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget tile() => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141E30) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFE8EDF5),
            ),
          ),
          child: Row(
            children: [
              const ShimmerBox(width: 48, height: 48, borderRadius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 150, height: 14),
                    SizedBox(height: 8),
                    ShimmerBox(width: 90, height: 10),
                  ],
                ),
              ),
              const ShimmerBox(width: 44, height: 18, borderRadius: 999),
            ],
          ),
        );

    if (asSliver) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => tile(),
            childCount: itemCount,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (_, i) => tile(),
    );
  }
}

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.child,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? child;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.withValues(alpha: 0.15);
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.6);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1 - 2 * t, 0),
              end: Alignment(1 - 2 * t, 0),
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(rect);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
