import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../bloc/export/export_bloc.dart';
import '../bloc/feedback/feedback_bloc.dart';

/// Step 4 — confirmation. Resets the draft and, after a short beat,
/// automatically returns to the User Details screen for the next entry.
class ThankYouScreen extends StatefulWidget {
  const ThankYouScreen({super.key});

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _redirect;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    // Keep the export count fresh for when the owner next opens it.
    context.read<ExportBloc>().add(const ExportCountRefreshed());

    _redirect = Timer(const Duration(milliseconds: 2600), _goBack);
  }

  void _goBack() {
    if (!mounted) return;
    context.read<FeedbackBloc>().add(const FeedbackReset());
    // Pop everything back to the first route (User Details / home).
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _redirect?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.elasticOut,
                ),
                child: Container(
                  height: 110,
                  width: 110,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 60),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Thank you!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your feedback has been saved successfully.\n'
                'Returning to collect the next one…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: _goBack,
                child: const Text('Add another now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
