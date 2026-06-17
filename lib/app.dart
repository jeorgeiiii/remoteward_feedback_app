import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/export/export_bloc.dart';
import 'presentation/bloc/feedback/feedback_bloc.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/user_details_screen.dart';

class FeedbackApp extends StatelessWidget {
  const FeedbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // App-wide singleton that drives top-level routing.
        BlocProvider.value(value: getIt<AuthBloc>()),
        // Session blocs live above MaterialApp so every screen can reach them.
        BlocProvider<FeedbackBloc>(create: (_) => getIt<FeedbackBloc>()),
        BlocProvider<ExportBloc>(create: (_) => getIt<ExportBloc>()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _RootGate(),
      ),
    );
  }
}

/// Decides what the user sees based on authentication state, and transitions
/// between login and the collection flow smoothly.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status && curr.status == AuthStatus.authenticated,
      listener: (context, state) {
        // Seed the feedback draft with the owner once signed in.
        if (state.user != null) {
          context.read<FeedbackBloc>().add(FeedbackStarted(state.user!));
          context.read<ExportBloc>().add(const ExportCountRefreshed());
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (prev, curr) => prev.status != curr.status,
        builder: (context, state) {
          final Widget screen = switch (state.status) {
            AuthStatus.unknown => const _Splash(),
            AuthStatus.unauthenticated => const LoginScreen(),
            AuthStatus.authenticated => const UserDetailsScreen(),
          };
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: KeyedSubtree(
              key: ValueKey(state.status),
              child: screen,
            ),
          );
        },
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
