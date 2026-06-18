import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/app_colors.dart';
import '../../core/utils/transitions.dart';
import '../bloc/feedback/feedback_bloc.dart';
import '../widgets/primary_button.dart';
import '../widgets/staggered_column.dart';
import '../widgets/step_progress.dart';
import 'thank_you_screen.dart';

/// Step 3 — attach screenshots, images, or videos, then submit.
class MediaCollectionScreen extends StatelessWidget {
  const MediaCollectionScreen({super.key});

  static final ImagePicker _picker = ImagePicker();

  Future<void> _pick(BuildContext context, _PickKind kind) async {
    final bloc = context.read<FeedbackBloc>();
    try {
      switch (kind) {
        case _PickKind.camera:
          final x = await _picker.pickImage(source: ImageSource.camera);
          if (x != null) bloc.add(MediaAdded(x.path));
          break;
        case _PickKind.images:
          final xs = await _picker.pickMultiImage();
          for (final x in xs) {
            bloc.add(MediaAdded(x.path));
          }
          break;
        case _PickKind.video:
          final x = await _picker.pickVideo(source: ImageSource.gallery);
          if (x != null) bloc.add(MediaAdded(x.path));
          break;
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access media.')),
        );
      }
    }
  }

  void _showPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _sheetTile(sheetContext, context, Icons.photo_camera_outlined,
                'Take a photo', _PickKind.camera),
            _sheetTile(sheetContext, context, Icons.photo_library_outlined,
                'Choose images', _PickKind.images),
            _sheetTile(sheetContext, context, Icons.videocam_outlined,
                'Choose a video', _PickKind.video),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile(BuildContext sheetContext, BuildContext screenContext,
      IconData icon, String label, _PickKind kind) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      onTap: () {
        Navigator.of(sheetContext).pop();
        _pick(screenContext, kind);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeedbackBloc, FeedbackState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == SubmitStatus.success) {
          Navigator.of(context).pushReplacement(
            FadeSlidePageRoute(page: const ThankYouScreen()),
          );
        } else if (state.status == SubmitStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error ?? 'Something went wrong')),
          );
        }
      },
      builder: (context, state) {
        final media = state.draft.mediaPaths;
        final submitting = state.status == SubmitStatus.submitting;
        return Scaffold(
          appBar: AppBar(title: const Text('Attach Media')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StepProgress(currentStep: 3),
                  const SizedBox(height: 28),
                  const Text(
                    'Add screenshots or video',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Optional, but visuals make bugs far easier to reproduce.',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: media.isEmpty
                        ? _EmptyState(onAdd: () => _showPickerSheet(context))
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                            itemCount: media.length + 1,
                            itemBuilder: (context, i) {
                              if (i == media.length) {
                                return _AddTile(
                                    onTap: () => _showPickerSheet(context));
                              }
                              return _MediaTile(
                                path: media[i],
                                onRemove: () => context
                                    .read<FeedbackBloc>()
                                    .add(MediaRemoved(media[i])),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Submit feedback',
                    icon: Icons.check_rounded,
                    isLoading: submitting,
                    onPressed: () => context
                        .read<FeedbackBloc>()
                        .add(const FeedbackSubmitted()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _PickKind { camera, images, video }

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return StaggeredColumn(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border,
                width: 1.4,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 44, color: AppColors.primary),
                SizedBox(height: 12),
                Text(
                  'Tap to add media',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: const Icon(Icons.add_rounded,
            color: AppColors.primary, size: 30),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _MediaTile({required this.path, required this.onRemove});

  bool get _isVideo {
    final ext = p.extension(path).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _isVideo
              ? Container(
                  color: AppColors.textPrimary,
                  child: const Icon(Icons.play_circle_outline_rounded,
                      color: Colors.white, size: 34),
                )
              : Image.file(File(path), fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
