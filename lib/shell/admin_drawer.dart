import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/admin_menu_badge_notifier.dart';
import '../widgets/admin_menu_badge_dot.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final AdminMenuBadges badges;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.badges = const AdminMenuBadges(),
  });

  static const communityIndex = 13;
  static const supportIndex = 14;
  static const warmupIndex = 11;

  static const titles = [
    'Dashboard',
    'Utenti',
    'Aziende',
    'Corsi',
    'Popup',
    'CreditJob',
    'Consensi job',
    'Consensi registrazione',
    'Role Play',
    'Ricerca normativa',
    'Analisi telefonata',
    'Warm-up',
    'Statistiche',
    'Community',
    'Assistenza',
    'Coupon',
    'Piani',
    'Costi',
    'Sicurezza',
    'Impostazioni',
  ];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.people_outline,
    Icons.business_outlined,
    Icons.menu_book_outlined,
    Icons.campaign_outlined,
    Icons.work_outline,
    Icons.rule_outlined,
    Icons.assignment_outlined,
    Icons.record_voice_over_outlined,
    Icons.balance_outlined,
    Icons.phone_in_talk_outlined,
    Icons.psychology_outlined,
    Icons.bar_chart_outlined,
    Icons.forum_outlined,
    Icons.support_agent_outlined,
    Icons.confirmation_number_outlined,
    Icons.layers_outlined,
    Icons.euro_outlined,
    Icons.security_outlined,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.headerGradientStart,
                  AppColors.headerGradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'BackOffice Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                const Text(
                  'Pannello mobile',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: titles.length,
              itemBuilder: (context, index) {
                final selected = index == selectedIndex;
                final showBadge = switch (index) {
                  communityIndex => badges.community,
                  supportIndex => badges.support,
                  _ => false,
                };
                return ListTile(
                  leading: Icon(
                    _icons[index],
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: Text(
                    titles[index],
                    style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  trailing: adminMenuBadgeDot(visible: showBadge),
                  selected: selected,
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
