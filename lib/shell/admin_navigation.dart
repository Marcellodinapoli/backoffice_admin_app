import 'package:flutter/material.dart';

/// Sezioni principali della shell post-login.
enum AdminSection {
  users,
  companies,
  courses,
  notifications,
  more,
}

extension AdminSectionX on AdminSection {
  String get title {
    switch (this) {
      case AdminSection.users:
        return 'Utenti';
      case AdminSection.companies:
        return 'Aziende';
      case AdminSection.courses:
        return 'Corsi';
      case AdminSection.notifications:
        return 'Notifiche';
      case AdminSection.more:
        return 'Altro';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminSection.users:
        return Icons.people_outline;
      case AdminSection.companies:
        return Icons.business_outlined;
      case AdminSection.courses:
        return Icons.menu_book_outlined;
      case AdminSection.notifications:
        return Icons.campaign_outlined;
      case AdminSection.more:
        return Icons.apps_rounded;
    }
  }

  IconData get selectedIcon {
    switch (this) {
      case AdminSection.users:
        return Icons.people;
      case AdminSection.companies:
        return Icons.business;
      case AdminSection.courses:
        return Icons.menu_book;
      case AdminSection.notifications:
        return Icons.campaign;
      case AdminSection.more:
        return Icons.apps;
    }
  }
}

/// Bottom navigation bar personalizzata.
class AdminBottomNav extends StatelessWidget {
  final AdminSection current;
  final ValueChanged<AdminSection> onChanged;

  const AdminBottomNav({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: current.index,
      onDestinationSelected: (i) => onChanged(AdminSection.values[i]),
      destinations: AdminSection.values
          .map(
            (s) => NavigationDestination(
              icon: Icon(s.icon),
              selectedIcon: Icon(s.selectedIcon),
              label: s.title,
            ),
          )
          .toList(),
    );
  }
}
