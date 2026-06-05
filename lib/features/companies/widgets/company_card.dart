import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/company.dart';
import '../../../shared/widgets/status_badge.dart';

class CompanyCard extends StatelessWidget {
  final Company company;
  final String? linkedStatus;
  final VoidCallback onTap;

  const CompanyCard({
    super.key,
    required this.company,
    this.linkedStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = linkedStatus ?? company.status;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.companyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (company.companyCode != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Codice: ${company.companyCode}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              StatusBadge.fromStatus(status),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
