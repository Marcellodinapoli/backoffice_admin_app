import 'package:flutter/material.dart';

import '../../../core/subscription/subscription_admin_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_user.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/subscription_card_summary.dart';

class UserCard extends StatelessWidget {
  final AppUser user;
  final String? companyName;
  final SubscriptionCardInfo? subscriptionInfo;
  final VoidCallback onTap;

  const UserCard({
    super.key,
    required this.user,
    this.companyName,
    this.subscriptionInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accentSoft,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.type == 'work' && companyName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        companyName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (user.type == 'public' && subscriptionInfo != null) ...[
                      const SizedBox(height: 10),
                      SubscriptionCardSummary(info: subscriptionInfo!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge.fromStatus(user.displayStatus),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
