import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A slim 3-segment progress bar shown across the collection flow so the user
/// always knows where they are. Segments animate as they fill.
class StepProgress extends StatelessWidget {
  final int currentStep; // 1-based
  final int totalSteps;

  const StepProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final filled = i < currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            height: 6,
            margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
