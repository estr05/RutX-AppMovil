import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppNotificationCard extends StatelessWidget {
  final String? title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onClose;

  const AppNotificationCard({
    super.key,
    this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.actionLabel,
    this.onAction,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.black08,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color border
            Container(width: 6, color: iconColor),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (title != null) ...[
                            Text(
                              title!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (actionLabel != null && onAction != null) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: onAction,
                              child: Text(
                                actionLabel!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: iconColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Close button
            if (onClose != null)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppTheme.textSecondary,
                  onPressed: onClose,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
