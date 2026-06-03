import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const _titles = [
    'Dashboard',
    'Utenti',
    'Aziende',
    'Popup',
    'Impostazioni',
    'CreditJob',
    'Costi',
    'Community',
    'Assistenza',
    'Sicurezza',
  ];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.people_outline,
    Icons.business_outlined,
    Icons.campaign_outlined,
    Icons.settings_outlined,
    Icons.work_outline,
    Icons.euro_outlined,
    Icons.forum_outlined,
    Icons.support_agent_outlined,
    Icons.security_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF1565C0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'BackOffice Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Pannello mobile',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _titles.length,
              itemBuilder: (context, index) {
                final selected = index == selectedIndex;
                return ListTile(
                  leading: Icon(
                    _icons[index],
                    color: selected
                        ? const Color(0xFF1565C0)
                        : Colors.grey[700],
                  ),
                  title: Text(
                    _titles[index],
                    style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? const Color(0xFF1565C0)
                          : Colors.black87,
                    ),
                  ),
                  selected: selected,
                  onTap: () => onSelect(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
