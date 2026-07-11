import 'package:flutter/foundation.dart';

class AdminMenuBadges {
  final bool community;
  final bool support;
  final bool warmup;
  final bool creditJob;

  const AdminMenuBadges({
    this.community = false,
    this.support = false,
    this.warmup = false,
    this.creditJob = false,
  });

  bool get hasAny => community || support || warmup || creditJob;
}

/// Badge sul menù drawer BackOffice (Community, Assistenza, Warm-up, CreditJob).
final class AdminMenuBadgeNotifier {
  AdminMenuBadgeNotifier._();

  static final AdminMenuBadgeNotifier instance = AdminMenuBadgeNotifier._();

  final ValueNotifier<AdminMenuBadges> badges =
      ValueNotifier(const AdminMenuBadges());
}
