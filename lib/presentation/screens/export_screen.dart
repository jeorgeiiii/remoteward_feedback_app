import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_colors.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/export/export_bloc.dart';
import '../widgets/primary_button.dart';
import '../widgets/staggered_column.dart';

/// Owner-only dashboard: shows how many records are stored and exports them to
/// CSV or PDF in scoped storage — gated behind device authentication.
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final owner = context.select((AuthBloc b) => b.state.user);
    return Scaffold(
      appBar: AppBar(title: const Text('Export & Account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: BlocConsumer<ExportBloc, ExportState>(
            listener: (context, state) {
              final messenger = ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar();
              switch (state.status) {
                case ExportStatus.success:
                  messenger.showSnackBar(SnackBar(
                    backgroundColor: AppColors.success,
                    content: Text('Saved to ${state.savedPath}'),
                  ));
                  if (state.pdfBytes != null) {
                    Printing.layoutPdf(onLayout: (_) async => state.pdfBytes!);
                  }
                  break;
                case ExportStatus.authFailed:
                  messenger.showSnackBar(const SnackBar(
                    content: Text('Authentication failed or cancelled.'),
                  ));
                  break;
                case ExportStatus.failure:
                  messenger.showSnackBar(
                    SnackBar(content: Text(state.error ?? 'Export failed')),
                  );
                  break;
                case ExportStatus.lockNotSet:
                  messenger.showSnackBar(SnackBar(
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 5),
                    content:
                        Text(state.error ?? 'Please set up a screen lock.'),
                  ));
                  break;
                default:
                  break;
              }
            },
            builder: (context, state) {
              final busy = state.status == ExportStatus.authenticating ||
                  state.status == ExportStatus.exporting;
              return StaggeredColumn(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white24,
                          backgroundImage: owner?.photoUrl != null
                              ? NetworkImage(owner!.photoUrl!)
                              : null,
                          child: owner?.photoUrl == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                owner?.name ?? 'Device Owner',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                owner?.email ?? '',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.inbox_rounded,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${state.entryCount}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'feedback entries collected',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 20, color: AppColors.textSecondary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You\'ll be asked to verify your identity before '
                            'the file is written to Downloads.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: busy ? 'Working…' : 'Export as PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    isLoading: busy,
                    onPressed: () => context
                        .read<ExportBloc>()
                        .add(const ExportRequested(ExportFormat.pdf)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => context
                            .read<ExportBloc>()
                            .add(const ExportRequested(ExportFormat.csv)),
                    icon: const Icon(Icons.table_chart_outlined,
                        color: AppColors.primary),
                    label: const Text('Export as CSV',
                        style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context
                        .read<AuthBloc>()
                        .add(const AuthSignOutRequested()),
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.error),
                    label: const Text('Sign out',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}