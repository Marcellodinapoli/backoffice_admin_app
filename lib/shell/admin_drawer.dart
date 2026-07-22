import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/admin_menu_badge_notifier.dart';
import '../widgets/admin_menu_badge_dot.dart';

class AdminDrawer extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelect;
  final AdminMenuBadges badges;

  const AdminDrawer({
    super.key,
    required this.selectedId,
    required this.onSelect,
    this.badges = const AdminMenuBadges(),
  });

  static const creditJobId = 'creditcore.credit_job';
  static const communityId = 'creditcore.community';
  static const supportId = 'creditcore.support';
  static const warmupId = 'creditcore.warmup';
  static const firstCreditCoreId = 'creditcore.dashboard';
  static const firstOutfitId = 'outfit.users';

  static const creditCoreItems = [
    (firstCreditCoreId, 'Dashboard', Icons.dashboard_outlined),
    ('creditcore.users', 'Utenti', Icons.people_outline),
    ('creditcore.companies', 'Aziende', Icons.business_outlined),
    ('creditcore.courses', 'Corsi', Icons.menu_book_outlined),
    ('creditcore.popup', 'Popup', Icons.campaign_outlined),
    (creditJobId, 'CreditJob', Icons.work_outline),
    ('creditcore.job_consents', 'Consensi job', Icons.rule_outlined),
    (
      'creditcore.registration_consents',
      'Consensi registrazione',
      Icons.assignment_outlined,
    ),
    ('creditcore.roleplay', 'Role Play', Icons.record_voice_over_outlined),
    ('creditcore.normative', 'Ricerca normativa', Icons.balance_outlined),
    ('creditcore.call_analysis', 'Analisi telefonata', Icons.phone_in_talk_outlined),
    (warmupId, 'Warm-up', Icons.psychology_outlined),
    ('creditcore.statistics', 'Statistiche', Icons.bar_chart_outlined),
    (communityId, 'Community', Icons.forum_outlined),
    (supportId, 'Assistenza', Icons.support_agent_outlined),
    ('creditcore.coupons', 'Coupon', Icons.confirmation_number_outlined),
    ('creditcore.plans', 'Piani', Icons.layers_outlined),
    ('creditcore.costs', 'Costi', Icons.euro_outlined),
    ('creditcore.ai_usage', 'Consumi AI', Icons.auto_awesome_outlined),
    ('creditcore.security', 'Sicurezza', Icons.security_outlined),
    ('creditcore.settings', 'Impostazioni', Icons.settings_outlined),
  ];

  static const outfitItems = [
    (firstOutfitId, 'Utenti', Icons.people_outline),
    ('outfit.support', 'Assistenza diretta', Icons.support_agent_outlined),
    ('outfit.privacy', 'Privacy', Icons.policy_outlined),
    ('outfit.coupons', 'Coupon', Icons.confirmation_number_outlined),
    ('outfit.alerts', 'Avvisi', Icons.campaign_outlined),
    ('outfit.notifications', 'Notifiche', Icons.notifications_outlined),
    ('outfit.plans', 'Piani', Icons.layers_outlined),
    ('outfit.prompts', 'Prompt AI', Icons.auto_awesome_outlined),
    ('outfit.ai_usage', 'Consumi AI', Icons.insights_outlined),
  ];

  static String titleFor(String id) {
    for (final item in [...creditCoreItems, ...outfitItems]) {
      if (item.$1 == id) return item.$2;
    }
    return '';
  }

  static String projectFor(String id) =>
      id.startsWith('outfit.') ? 'Outfit' : 'CreditCore';

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
            child: ListView(
              children: [
                _projectMenu(
                  context,
                  title: 'CreditCore',
                  items: creditCoreItems,
                  initiallyExpanded: selectedId.startsWith('creditcore.'),
                ),
                _projectMenu(
                  context,
                  title: 'Outfit',
                  items: outfitItems,
                  initiallyExpanded: selectedId.startsWith('outfit.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectMenu(
    BuildContext context, {
    required String title,
    required List<(String, String, IconData)> items,
    required bool initiallyExpanded,
  }) {
    final hasBadge = title == 'CreditCore' &&
        (badges.creditJob || badges.warmup || badges.community || badges.support);
    return ExpansionTile(
      key: PageStorageKey('drawer.project.$title'),
      initiallyExpanded: initiallyExpanded,
      leading: Icon(title == 'Outfit' ? Icons.checkroom_outlined : Icons.account_balance_outlined),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          adminMenuBadgeDot(visible: hasBadge),
          const Icon(Icons.expand_more),
        ],
      ),
      children: items.map((item) {
        final selected = item.$1 == selectedId;
        final showBadge = switch (item.$1) {
          creditJobId => badges.creditJob,
          warmupId => badges.warmup,
          communityId => badges.community,
          supportId => badges.support,
          _ => false,
        };
        return ListTile(
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          leading: Icon(
            item.$3,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
          title: Text(
            item.$2,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          trailing: adminMenuBadgeDot(visible: showBadge),
          selected: selected,
          onTap: () {
            Navigator.pop(context);
            onSelect(item.$1);
          },
        );
      }).toList(),
    );
  }
}
