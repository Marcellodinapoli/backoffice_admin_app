import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../roleplay/pages/roleplay_page.dart';
import '../../settings/pages/settings_page.dart';
import '../../statistics/pages/statistics_page.dart';

/// Hub per sezioni secondarie (Roleplay, Statistiche, Impostazioni).
class MorePage extends StatelessWidget {
  final void Function(Widget page, String title) onNavigate;

  const MorePage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreItem(
        title: 'Role Play',
        subtitle: 'Simulazioni formazione',
        icon: Icons.record_voice_over_outlined,
        color: AppColors.info,
        background: AppColors.infoBg,
        page: const RoleplayPage(),
      ),
      _MoreItem(
        title: 'Statistiche',
        subtitle: 'KPI e panoramica',
        icon: Icons.bar_chart_rounded,
        color: AppColors.primary,
        background: AppColors.accentSoft,
        page: const StatisticsPage(),
      ),
      _MoreItem(
        title: 'Impostazioni',
        subtitle: 'Manutenzione e sistema',
        icon: Icons.settings_outlined,
        color: AppColors.warning,
        background: AppColors.warningBg,
        page: const SettingsPage(),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text(
          'Altre sezioni',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Role Play, statistiche e configurazione',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        ...items.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onNavigate(item.page, item.title),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;
  final Widget page;

  const _MoreItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
    required this.page,
  });
}
