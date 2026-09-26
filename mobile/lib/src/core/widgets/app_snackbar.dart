import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

abstract final class AppSnackbar {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.successGreen, Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.errorRed, Icons.error_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.infoBlue, Icons.info_outline);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: AppColors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
