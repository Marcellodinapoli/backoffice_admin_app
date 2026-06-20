import 'package:flutter/material.dart';

import '../../core/subscription/subscription_admin_helper.dart';
import '../../core/theme/app_colors.dart';

class SubscriptionCardSummary extends StatelessWidget {
  final SubscriptionCardInfo info;

  const SubscriptionCardSummary({super.key, required this.info});

  Color _barColor(double ratio) {
    if (ratio >= 1.0) return const Color(0xFFD32F2F);
    if (ratio >= subscriptionLimitWarningRatio) return const Color(0xFFE65100);
    return const Color(0xFF2E7D32);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Piano', info.planLabel, fontWeight: FontWeight.w600),
        const SizedBox(height: 4),
        _row('Scadenza', info.expiryLabel),
        const SizedBox(height: 8),
        if (info.unlimited)
          Text(
            '${info.limitLabel}: illimitato',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          )
        else if (info.limit != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  info.limitLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${info.used ?? 0}/${info.limit}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _barColor(info.ratio ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: info.ratio,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: _barColor(info.ratio ?? 0),
            ),
          ),
          if (info.nearLimit && !info.atLimit)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Soglia ${(subscriptionLimitWarningRatio * 100).round()}% raggiunta',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFE65100),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _row(String label, String value, {FontWeight? fontWeight}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ],
    );
  }
}
