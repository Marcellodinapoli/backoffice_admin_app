import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const titles = [
    'Dashboard',
    'Utenti',
    'Popup',
    'CreditJob',
    'Impostazioni',
  ];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.people_outline,
    Icons.campaign_outlined,
    Icons.work_outline,
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
