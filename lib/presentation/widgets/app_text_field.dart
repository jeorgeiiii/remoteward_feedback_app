import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = '',
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.icon,
    this.validator,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
          maxLines: maxLines,
          validator: validator,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.textTertiary, size: 20)
                : null,
          ),
        ),
      ],
    );
  }
}
