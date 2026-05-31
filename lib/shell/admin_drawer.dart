import 'package:flutter/material.dart';

import '../backoffice_web_pages/bk_dashboard_page.dart';
import '../backoffice_web_pages/bk_users_page.dart' as users;
import '../backoffice_web_pages/bk_courses_page.dart' as courses;

class AdminDrawer extends StatelessWidget {
  final Function(Widget) onSelect;

  const AdminDrawer({
    super.key,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF1B263B),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "BackOffice Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Pannello di controllo",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          _buildItem(
            context,
            icon: Icons.dashboard_outlined,
            title: "Dashboard",
            page: const BkDashboardPage(),
          ),

          _buildItem(
            context,
            icon: Icons.people_outline,
            title: "Utenti",
            page: users.BkUsersPage(),
          ),

          _buildItem(
            context,
            icon: Icons.school_outlined,
            title: "Corsi",
            page: courses.BkCoursesPage(),
          ),

          const Divider(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Widget page,
      }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () => onSelect(page),
    );
  }
}
