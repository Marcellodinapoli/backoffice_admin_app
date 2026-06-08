class DashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int blockedUsers;
  final int deletedUsers;
  final int newUsersThisMonth;
  final int totalCompanies;
  final int totalCourses;
  final int totalJobOffers;
  final int activeJobOffers;
  final int pendingJobOffers;
  final int blockedJobOffers;
  final int newJobOffersThisMonth;
  final int expiredJobOffers;
  final int totalApplications;
  final int totalRoleplay;

  const DashboardStats({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.blockedUsers = 0,
    this.deletedUsers = 0,
    this.newUsersThisMonth = 0,
    this.totalCompanies = 0,
    this.totalCourses = 0,
    this.totalJobOffers = 0,
    this.activeJobOffers = 0,
    this.pendingJobOffers = 0,
    this.blockedJobOffers = 0,
    this.newJobOffersThisMonth = 0,
    this.expiredJobOffers = 0,
    this.totalApplications = 0,
    this.totalRoleplay = 0,
  });
}

bool _readFirestoreBool(dynamic raw, {bool defaultValue = false}) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final normalized = raw.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return defaultValue;
}

class MaintenanceSettings {
  final bool enabled;
  final String section;

  const MaintenanceSettings({
    required this.enabled,
    required this.section,
  });

  factory MaintenanceSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const MaintenanceSettings(enabled: false, section: 'Tutto');
    }

    final section = data['section']?.toString().trim();
    return MaintenanceSettings(
      enabled: _readFirestoreBool(data['enabled']),
      section: (section == null || section.isEmpty) ? 'Tutto' : section,
    );
  }
}

/// Interruttore globale push (`settings/notifications`).
class NotificationSettings {
  final bool enabled;

  const NotificationSettings({required this.enabled});

  factory NotificationSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const NotificationSettings(enabled: false);
    }
    return NotificationSettings(
      enabled: _readFirestoreBool(data['enabled']),
    );
  }
}
