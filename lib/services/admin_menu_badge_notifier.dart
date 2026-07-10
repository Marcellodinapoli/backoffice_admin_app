import 'package:flutter/foundation.dart';

class AdminMenuBadges {
  final bool community;
  final bool support;

  const AdminMenuBadges({
    this.community = false,
    this.support = false,
  });

  bool get hasAny => community || support;
}

/// Badge sul menù drawer BackOffice (Community + Assistenza).
final class AdminMenuBadgeNotifier {
  AdminMenuBadgeNotifier._();

  static final AdminMenuBadgeNotifier instance = AdminMenuBadgeNotifier._();

  final ValueNotifier<AdminMenuBadges> badges =
      ValueNotifier(const AdminMenuBadges());
}
