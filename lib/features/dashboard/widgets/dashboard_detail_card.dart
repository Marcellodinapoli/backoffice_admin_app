import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class DashboardDetailItem {
  final String label;
  final int value;
  final Color color;

  const DashboardDetailItem(this.label, this.value, this.color);
}

class DashboardDetailCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accentColor;
  final List<DashboardDetailItem>? details;

  const DashboardDetailCard({
    super.key,
    required this.title,
    required this.value,
    required this.accentColor,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: -0.5,
              ),
            ),
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 10),
              ...details!.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${item.value}',
                        style: TextStyle(
                          fontSize: 13,
                          color: item.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
