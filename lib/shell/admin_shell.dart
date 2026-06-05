import 'package:flutter/material.dart';

import '../auth/admin_login_page.dart';
import '../core/theme/app_colors.dart';
import '../features/creditjob/pages/creditjob_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/notifications/pages/notifications_page.dart';
import '../features/settings/pages/settings_page.dart';
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
    const pages = [
      DashboardPage(),
      UsersPage(),
      NotificationsPage(),
      CreditJobPage(),
      SettingsPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientHeader(
        title: 'BackOffice Admin',
        subtitle: AdminDrawer.titles[_index],
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      drawer: AdminDrawer(
        selectedIndex: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
    );
  }
}
