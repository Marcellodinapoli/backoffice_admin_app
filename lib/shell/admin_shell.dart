import 'package:flutter/material.dart';

import 'admin_drawer.dart';
import '../services/auth_service.dart';
import '../auth/admin_login_page.dart';
import '../backoffice_web_pages/bk_dashboard_page.dart';
import '../backoffice_web_pages/bk_users_page.dart';
import '../backoffice_web_pages/bk_courses_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  Widget _currentPage = BkDashboardPage(); // ← tolto const
  final AuthService _authService = AuthService();

  void _navigate(Widget page) {
    setState(() {
      _currentPage = page;
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("BackOffice Admin"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: AdminDrawer(onSelect: _navigate),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentPage,
      ),
    );
  }
}
