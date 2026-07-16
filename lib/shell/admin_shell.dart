import 'package:credit_calc_core/credit_calc_core.dart';
import 'package:flutter/material.dart';

import '../auth/admin_login_page.dart';
import '../backoffice_web_pages/bk_community_page.dart';
import '../backoffice_web_pages/bk_costs_page.dart';
import '../backoffice_web_pages/bk_security_page.dart';
import '../backoffice_web_pages/bk_support_page.dart';
import '../core/subscription/plan_limits_refresh.dart';
import '../core/theme/app_colors.dart';
import '../features/companies/pages/companies_page.dart';
import '../features/courses/pages/courses_page.dart';
import '../features/creditjob/pages/creditjob_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/notifications/pages/notifications_page.dart';
import '../features/roleplay/pages/roleplay_page.dart';
import '../features/call_analysis/pages/call_analysis_page.dart';
import '../features/normative_search/pages/normative_search_page.dart';
import '../features/consents/pages/versioned_consent_page.dart';
import '../features/coupons/pages/coupons_page.dart';
import '../features/plans/pages/plans_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/statistics/pages/statistics_page.dart';
import '../features/users/pages/users_page.dart';
import '../features/warmup/pages/warmup_monitoring_page.dart';
import '../outfit/outfit_pages.dart';
import '../services/admin_menu_badge_controller.dart';
import '../services/admin_menu_badge_notifier.dart';
import '../services/auth_service.dart';
import '../shared/widgets/gradient_header.dart';
import 'admin_drawer.dart';

/// Shell principale post-login. Il login esistente naviga qui senza modifiche.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  String _selectedId = 'creditcore.dashboard';
  final _authService = AuthService();
  late final Map<String, Widget> _pageInstances = {
    ..._creditPages,
  };

  @override
  void initState() {
    super.initState();
    AdminMenuBadgeController.instance.start();
  }

  @override
  void dispose() {
    AdminMenuBadgeController.instance.stop();
    super.dispose();
  }

  static const _creditPages = <String, Widget>{
    'creditcore.dashboard': DashboardPage(),
    'creditcore.users': UsersPage(),
    'creditcore.companies': CompaniesPage(),
    'creditcore.courses': CoursesPage(),
    'creditcore.popup': NotificationsPage(),
    'creditcore.credit_job': CreditJobPage(),
    'creditcore.job_consents': JobConsentsPage(),
    'creditcore.registration_consents': RegistrationConsentsPage(),
    'creditcore.roleplay': RoleplayPage(),
    'creditcore.normative': NormativeSearchPage(),
    'creditcore.call_analysis': CallAnalysisPage(),
    'creditcore.warmup': WarmupMonitoringPage(),
    'creditcore.statistics': StatisticsPage(),
    'creditcore.community': BkCommunityPage(),
    'creditcore.support': BkSupportPage(),
    'creditcore.coupons': CouponsPage(),
    'creditcore.plans': PlansPage(),
    'creditcore.costs': BkCostsPage(),
    'creditcore.security': BkSecurityPage(),
    'creditcore.settings': SettingsPage(),
  };

  static final _outfitPageBuilders = <String, Widget Function()>{
    'outfit.users': () => const OutfitUsersPage(),
    'outfit.privacy': () => const OutfitPrivacyPage(),
    'outfit.coupons': () => const OutfitCouponsPage(),
    'outfit.plans': () => const OutfitPlansPage(),
    'outfit.prompts': () => const OutfitPromptsPage(),
  };

  static final _pageIds = [
    ..._creditPages.keys,
    ..._outfitPageBuilders.keys,
  ];

  void _selectPage(String id) {
    final builder = _outfitPageBuilders[id];
    if (builder != null) _pageInstances.putIfAbsent(id, builder);
    setState(() => _selectedId = id);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Esci'),
        content: const Text('Vuoi uscire dal BackOffice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _authService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex =
        _pageIds.indexOf(_selectedId).clamp(0, _pageIds.length - 1).toInt();
    final selectedId = _pageIds[safeIndex];

    return ValueListenableBuilder<AdminMenuBadges>(
      valueListenable: AdminMenuBadgeNotifier.instance.badges,
      builder: (context, badges, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: GradientHeader(
            title: 'BackOffice Admin',
            subtitle:
                '${AdminDrawer.projectFor(selectedId)} · ${AdminDrawer.titleFor(selectedId)}',
            leading: Builder(
              builder: (context) => Badge(
                isLabelVisible: badges.warmup,
                backgroundColor: Colors.red.shade700,
                smallSize: 12,
                offset: const Offset(-2, 2),
                padding: EdgeInsets.zero,
                child: IconButton(
                  tooltip: 'Menù',
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Logout',
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          drawer: AdminDrawer(
            selectedId: selectedId,
            badges: badges,
            onSelect: (id) {
              _selectPage(id);
              if (id == AdminDrawer.communityId) {
                AdminMenuBadgeController.markCommunityVisited();
              } else if (id == AdminDrawer.supportId) {
                AdminMenuBadgeController.markSupportVisited();
              } else if (id == AdminDrawer.creditJobId) {
                AdminMenuBadgeController.markCreditJobVisited();
              }
              if (id == 'creditcore.users' || id == 'creditcore.companies') {
                PublicPlanLimitsConfigService.ensureLoaded().then((_) {
                  PlanLimitsRefresh.bump();
                });
              }
            },
          ),
          body: SafeArea(
            top: false,
            child: IndexedStack(
              index: safeIndex,
              children: [
                for (final id in _pageIds)
                  _pageInstances[id] ?? const SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
    );
  }
}
