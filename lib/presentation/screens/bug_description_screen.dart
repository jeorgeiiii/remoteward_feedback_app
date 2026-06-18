import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/transitions.dart';
import '../bloc/feedback/feedback_bloc.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/staggered_column.dart';
import '../widgets/step_progress.dart';
import 'media_collection_screen.dart';

/// Step 2 — captures a short issue title and a detailed description.
class BugDescriptionScreen extends StatefulWidget {
  const BugDescriptionScreen({super.key});

  @override
  State<BugDescriptionScreen> createState() => _BugDescriptionScreenState();
}

class _BugDescriptionScreenState extends State<BugDescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Restore any previously entered values if the user navigates back/forward.
    final draft = context.read<FeedbackBloc>().state.draft;
    _title.text = draft.issueTitle;
    _description.text = draft.description;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    context.read<FeedbackBloc>().add(BugDetailsSubmitted(
          title: _title.text.trim(),
          description: _description.text.trim(),
        ));
    Navigator.of(context).push(
      FadeSlidePageRoute(page: const MediaCollectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Describe the Issue')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: StaggeredColumn(
              children: [
                const StepProgress(currentStep: 2),
                const SizedBox(height: 28),
                const Text(
                  'What went wrong?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Give the issue a short title, then describe it in detail.',
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'Issue title',
                  hint: 'App crashes on checkout',
                  controller: _title,
                  icon: Icons.label_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'A short title helps' : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Detailed description',
                  hint: 'Steps to reproduce, what you expected, what happened…',
                  controller: _description,
                  maxLines: 7,
                  textInputAction: TextInputAction.newline,
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Please add a little more detail'
                      : null,
                ),
                const SizedBox(height: 36),
                PrimaryButton(
                  label: 'Add media',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
