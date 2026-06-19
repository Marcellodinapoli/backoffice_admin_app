import 'package:flutter/material.dart';

import '../auth/admin_login_page.dart';
import '../backoffice_web_pages/bk_community_page.dart';
import '../backoffice_web_pages/bk_costs_page.dart';
import '../backoffice_web_pages/bk_security_page.dart';
import '../backoffice_web_pages/bk_support_page.dart';
import '../core/theme/app_colors.dart';
import '../features/companies/pages/companies_page.dart';
import '../features/courses/pages/courses_page.dart';
import '../features/creditjob/pages/creditjob_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/notifications/pages/notifications_page.dart';
import '../features/roleplay/pages/roleplay_page.dart';
import '../features/consents/pages/versioned_consent_page.dart';
import '../features/coupons/pages/coupons_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/statistics/pages/statistics_page.dart';
import '../features/users/pages/users_page.dart';
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
  int _index = 0;
  final _authService = AuthService();

  static const _pages = [
    DashboardPage(),
    UsersPage(),
    CompaniesPage(),
    CoursesPage(),
    NotificationsPage(),
    CreditJobPage(),
    JobConsentsPage(),
    RegistrationConsentsPage(),
    RoleplayPage(),
    StatisticsPage(),
    BkCommunityPage(),
    BkSupportPage(),
    CouponsPage(),
    BkCostsPage(),
    BkSecurityPage(),
    SettingsPage(),
  ];

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
    final safeIndex = _index.clamp(0, _pages.length - 1);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientHeader(
        title: 'BackOffice Admin',
        subtitle: AdminDrawer.titles[safeIndex],
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      drawer: AdminDrawer(
        selectedIndex: safeIndex,
        onSelect: (i) => setState(() => _index = i),
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: safeIndex,
          children: _pages,
        ),
      ),
    );
  }
}
