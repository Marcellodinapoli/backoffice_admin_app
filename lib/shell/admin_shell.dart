import 'package:credit_calc_core/credit_calc_core.dart';
import 'package:flutter/material.dart';

import '../auth/admin_login_page.dart';
import '../home/project_selection_page.dart';
import '../backoffice_web_pages/bk_community_page.dart';
import '../backoffice_web_pages/bk_costs_page.dart';
import '../backoffice_web_pages/bk_security_page.dart';
import '../backoffice_web_pages/bk_support_page.dart';
import '../core/subscription/plan_limits_refresh.dart';
import '../core/theme/app_colors.dart';
import '../features/ai_usage/pages/ai_usage_page.dart';
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
import '../outfit/outfit_ai_usage_page.dart';
import '../outfit/outfit_alerts_page.dart';
import '../outfit/outfit_notifications_page.dart';
import '../outfit/outfit_pages.dart';
import '../services/admin_menu_badge_controller.dart';
import '../services/admin_menu_badge_notifier.dart';
import '../services/auth_service.dart';
import '../shared/widgets/gradient_header.dart';
import 'admin_drawer.dart';

class AdminShell extends StatefulWidget {
  final String initialSelectedId;

  const AdminShell({
    super.key,
    this.initialSelectedId = AdminDrawer.firstCreditCoreId,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late String _selectedId;
  final _authService = AuthService();
  final Map<String, Widget> _pageInstances = {};

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
    _ensurePage(_selectedId);
    AdminMenuBadgeController.instance.start();
  }

  @override
  void dispose() {
    AdminMenuBadgeController.instance.stop();
    super.dispose();
  }

  /// Ordine voci CreditCore (allineato al drawer).
  static const _creditPageIds = <String>[
    'creditcore.dashboard',
    'creditcore.users',
    'creditcore.companies',
    'creditcore.courses',
    'creditcore.popup',
    'creditcore.credit_job',
    'creditcore.job_consents',
    'creditcore.registration_consents',
    'creditcore.roleplay',
    'creditcore.normative',
    'creditcore.call_analysis',
    'creditcore.warmup',
    'creditcore.statistics',
    'creditcore.community',
    'creditcore.support',
    'creditcore.coupons',
    'creditcore.plans',
    'creditcore.costs',
    'creditcore.ai_usage',
    'creditcore.security',
    'creditcore.settings',
  ];

  /// Ordine voci Outfit (allineato al drawer).
  static const _outfitPageIds = <String>[
    'outfit.users',
    'outfit.privacy',
    'outfit.coupons',
    'outfit.alerts',
    'outfit.notifications',
    'outfit.plans',
    'outfit.prompts',
    'outfit.ai_usage',
  ];

  bool _isKnownPage(String id) =>
      _creditPageIds.contains(id) || _outfitPageIds.contains(id);

  Widget _buildPage(String id) {
    return switch (id) {
      'creditcore.dashboard' => const DashboardPage(),
      'creditcore.users' => const UsersPage(),
      'creditcore.companies' => const CompaniesPage(),
      'creditcore.courses' => const CoursesPage(),
      'creditcore.popup' => const NotificationsPage(),
      'creditcore.credit_job' => const CreditJobPage(),
      'creditcore.job_consents' => const JobConsentsPage(),
      'creditcore.registration_consents' => const RegistrationConsentsPage(),
      'creditcore.roleplay' => const RoleplayPage(),
      'creditcore.normative' => const NormativeSearchPage(),
      'creditcore.call_analysis' => const CallAnalysisPage(),
      'creditcore.warmup' => const WarmupMonitoringPage(),
      'creditcore.statistics' => const StatisticsPage(),
      'creditcore.community' => const BkCommunityPage(),
      'creditcore.support' => const BkSupportPage(),
      'creditcore.coupons' => const CouponsPage(),
      'creditcore.plans' => const PlansPage(),
      'creditcore.costs' => const BkCostsPage(),
      'creditcore.ai_usage' => const AiUsagePage(),
      'creditcore.security' => const BkSecurityPage(),
      'creditcore.settings' => const SettingsPage(),
      'outfit.users' => const OutfitUsersPage(),
      'outfit.privacy' => const OutfitPrivacyPage(),
      'outfit.coupons' => const OutfitCouponsPage(),
      'outfit.alerts' => const OutfitAlertsPage(),
      'outfit.notifications' => const OutfitNotificationsPage(),
      'outfit.plans' => const OutfitPlansPage(),
      'outfit.prompts' => const OutfitPromptsPage(),
      'outfit.ai_usage' => const OutfitAiUsagePage(),
      _ => const SizedBox.shrink(),
    };
  }

  void _ensurePage(String id) {
    if (!_isKnownPage(id)) return;
    _pageInstances.putIfAbsent(id, () => _buildPage(id));
  }

  void _selectPage(String id) {
    if (!_isKnownPage(id)) return;
    _ensurePage(id);
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
    final selectedId =
        _isKnownPage(_selectedId) ? _selectedId : AdminDrawer.firstCreditCoreId;
    _ensurePage(selectedId);

    return ValueListenableBuilder<AdminMenuBadges>(
      valueListenable: AdminMenuBadgeNotifier.instance.badges,
      builder: (context, badges, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: GradientHeader(
            title: 'BackOffice Admin',
            subtitle:
                '${AdminDrawer.projectFor(selectedId)} · ${AdminDrawer.titleFor(selectedId)}',
            leadingWidth: 104,
            leading: Builder(
              builder: (context) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Torna ai progetti',
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProjectSelectionPage(),
                        ),
                      );
                    },
                  ),
                  Badge(
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
                ],
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
          // Navigazione per id (niente IndexedStack/indice): evita mismatch
          // quando si aggiungono voci Outfit.
          body: SafeArea(
            top: false,
            bottom: true,
            child: KeyedSubtree(
              key: ValueKey<String>(selectedId),
              child: _pageInstances[selectedId] ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
