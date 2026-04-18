import 'package:flutter/material.dart';

mixin StaggeredAnimationMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  late AnimationController animationController;
  late List<Animation<double>> fadeAnimations;

  void initStaggeredAnimations({
    int count = 10,
    Duration duration = const Duration(milliseconds: 900),
    double step = 0.06,
  }) {
    animationController = AnimationController(vsync: this, duration: duration);
    fadeAnimations = List.generate(count, (i) {
      final start = (i * step).clamp(0.0, 0.8);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
    animationController.forward();
  }

  void disposeStaggeredAnimations() {
    animationController.dispose();
  }

  Widget fadeAt(int index, Widget child) {
    if (index >= fadeAnimations.length) return child;
    return FadeTransition(opacity: fadeAnimations[index], child: child);
  }
}
