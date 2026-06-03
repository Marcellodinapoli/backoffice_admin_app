import 'package:flutter/material.dart';

import '../auth/admin_login_page.dart';
import '../backoffice_web_pages/bk_announcements_page.dart';
import '../backoffice_web_pages/bk_community_page.dart';
import '../backoffice_web_pages/bk_companies_page.dart';
import '../backoffice_web_pages/bk_costs_page.dart';
import '../backoffice_web_pages/bk_dashboard_page.dart';
import '../backoffice_web_pages/bk_jobs_page.dart';
import '../backoffice_web_pages/bk_security_page.dart';
import '../backoffice_web_pages/bk_settings_page.dart';
import '../backoffice_web_pages/bk_support_page.dart';
import '../backoffice_web_pages/bk_users_page.dart';
import '../services/auth_service.dart';
import 'admin_drawer.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  final AuthService _authService = AuthService();

  static const _titles = AdminDrawer._titles;

  final List<Widget> _pages = const [
    BkDashboardPage(),
    BkUsersPage(),
    BkCompaniesPage(),
    BkAnnouncementsPage(),
    BkSettingsPage(),
    BkJobsPage(),
    BkCostsPage(),
    BkCommunityPage(),
    BkSupportPage(),
    BkSecurityPage(),
  ];

  void _navigate(int index) {
    setState(() => _index = index);
    Navigator.pop(context);
  }

  Future<void> _logout() async {
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Text(_titles[safeIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: AdminDrawer(
        selectedIndex: safeIndex,
        onSelect: _navigate,
      ),
      body: IndexedStack(
        index: safeIndex,
        children: _pages,
      ),
    );
  }
}
