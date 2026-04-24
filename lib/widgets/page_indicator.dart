import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Five small dots arranged in a horizontal row — shows which hub page is active.
class PageIndicator extends StatelessWidget {
  final int count;
  final int current;

  const PageIndicator({super.key, required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? CircleHub.accent : CircleHub.textDim,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
