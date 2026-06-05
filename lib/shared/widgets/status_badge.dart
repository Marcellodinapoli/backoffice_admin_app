import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  factory StatusBadge.fromStatus(String status) {
    switch (status) {
      case 'active':
      case 'approved':
        return const StatusBadge(
          label: 'Attivo',
          color: AppColors.success,
          background: AppColors.successBg,
        );
      case 'blocked':
      case 'rejected':
        return const StatusBadge(
          label: 'Bloccato',
          color: AppColors.error,
          background: AppColors.errorBg,
        );
      case 'standby':
      case 'pending':
        return StatusBadge(
          label: status == 'pending' ? 'In attesa' : 'Standby',
          color: AppColors.warning,
          background: AppColors.warningBg,
        );
      case 'deleted':
        return const StatusBadge(
          label: 'Eliminato',
          color: AppColors.textMuted,
          background: AppColors.surfaceVariant,
        );
      default:
        return StatusBadge(
          label: status,
          color: AppColors.textSecondary,
          background: AppColors.surfaceVariant,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
