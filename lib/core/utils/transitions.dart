import 'package:flutter/material.dart';

/// A shared slide+fade page transition used across the whole app so navigation
/// feels consistent and smooth rather than the default platform cut.
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  FadeSlidePageRoute({required this.page, RouteSettings? settings})
      : super(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );

  final Widget page;
}
