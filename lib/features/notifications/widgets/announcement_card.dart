import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/announcement.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final int? seenCount;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.seenCount,
    this.onToggle,
    this.onDelete,
    this.onEdit,
  });

  Color _typeColor(String type) {
    switch (type) {
      case 'alert':
        return AppColors.errorBg;
      case 'aggiornamento':
        return AppColors.warningBg;
      default:
        return AppColors.accentSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = announcement.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(announcement.createdAt!.toDate())
        : '';

    final reads = seenCount ?? announcement.seenCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: _typeColor(announcement.type),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  announcement.active
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: 18,
                  color: announcement.active
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              announcement.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${announcement.type} · Target: ${announcement.target} · $date',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            Text(
              '👥 ${announcement.targetCount} utenti · 👁 $reads lette',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Modifica',
                  ),
                if (onToggle != null)
                  IconButton(
                    icon: Icon(
                      announcement.active
                          ? Icons.toggle_on
                          : Icons.toggle_off,
                      size: 28,
                      color: announcement.active
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                    onPressed: onToggle,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: AppColors.error),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
