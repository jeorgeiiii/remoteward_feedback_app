import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/transitions.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/export/export_bloc.dart';
import '../bloc/feedback/feedback_bloc.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/staggered_column.dart';
import '../widgets/step_progress.dart';
import 'bug_description_screen.dart';
import 'export_screen.dart';

/// Step 1 — collects details of the user submitting feedback. Also the screen
/// the flow returns to after each submission, so it doubles as the home.
class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _contact = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    context.read<FeedbackBloc>().add(UserDetailsSubmitted(
          name: _name.text.trim(),
          email: _email.text.trim(),
          contact: _contact.text.trim(),
        ));
    Navigator.of(context).push(
      FadeSlidePageRoute(page: const BugDescriptionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final owner = context.select((AuthBloc b) => b.state.user);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Feedback'),
        actions: [
          // Export entry point for the device owner.
          IconButton(
            tooltip: 'Export & account',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () {
              context.read<ExportBloc>().add(const ExportCountRefreshed());
              Navigator.of(context).push(
                FadeSlidePageRoute(page: const ExportScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: StaggeredColumn(
              children: [
                const StepProgress(currentStep: 1),
                const SizedBox(height: 28),
                Text(
                  'Who is this feedback from?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  owner == null
                      ? 'Enter the user\'s contact details.'
                      : 'Signed in as ${owner.email}. Enter the user\'s details.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'Full name',
                  hint: 'Jane Doe',
                  controller: _name,
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Email',
                  hint: 'jane@example.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.alternate_email_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(v);
                    return ok ? null : 'Enter a valid email';
                  },
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Contact number',
                  hint: '+1 555 123 4567',
                  controller: _contact,
                  keyboardType: TextInputType.phone,
                  icon: Icons.phone_outlined,
                  textInputAction: TextInputAction.done,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Contact is required'
                      : null,
                ),
                const SizedBox(height: 36),
                PrimaryButton(
                  label: 'Continue',
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
