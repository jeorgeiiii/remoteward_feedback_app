import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../bloc/auth/auth_bloc.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Soft branded backdrop.
          Positioned(
            top: -120,
            right: -80,
            child: _blob(260, AppColors.primary.withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _blob(220, AppColors.accent.withValues(alpha: 0.10)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Container(
                    height: 88,
                    width: 88,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bug_report_rounded,
                        color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Feedback Collector',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Collect structured user feedback and bug reports, '
                    'then export securely — all on this device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(flex: 4),
                  BlocConsumer<AuthBloc, AuthState>(
                    listener: (context, state) {
                      if (state.error != null) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(state.error!)),
                          );
                      }
                    },
                    builder: (context, state) {
                      return PrimaryButton(
                        label: 'Continue with Google',
                        icon: Icons.login_rounded,
                        isLoading: state.isSubmitting,
                        onPressed: () => context
                            .read<AuthBloc>()
                            .add(const AuthGoogleSignInRequested()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Only the device owner can sign in.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
