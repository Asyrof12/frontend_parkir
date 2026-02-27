import 'package:flutter/material.dart';
import 'colors.dart';

enum NotificationType { success, error, info }

class AppNotification {
  static void show({
    required BuildContext context,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    IconData icon;
    Color bgColor;

    switch (type) {
      case NotificationType.success:
        icon = Icons.check_circle_rounded;
        bgColor = AppColors.success;
        break;
      case NotificationType.error:
        icon = Icons.error_rounded;
        bgColor = AppColors.error;
        break;
      case NotificationType.info:
        icon = Icons.info_rounded;
        bgColor = AppColors.primary;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(

            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.45,
          left: 40,
          right: 40,
        ),




        duration: duration,
        elevation: 0,
      ),
    );



  }

  static String _getTitle(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return 'Sukses';
      case NotificationType.error:
        return 'Gagal';
      case NotificationType.info:
        return 'Informasi';
    }
  }

  static void success(BuildContext context, String message) {
    show(context: context, message: message, type: NotificationType.success);
  }

  static void error(BuildContext context, String message) {
    show(context: context, message: message, type: NotificationType.error);
  }

  static void info(BuildContext context, String message) {
    show(context: context, message: message, type: NotificationType.info);
  }
}
