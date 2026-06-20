import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String companyName;
  final String email;
  final String status;
  final String? companyCode;
  final String? phone;
  final String? piva;
  final String? website;
  final String? referencePerson;
  final String? referenceRole;
  final String? blockedReason;
  final Timestamp? blockedAt;
  final Timestamp? activatedAt;
  final String? subscriptionPlan;
  final bool lifetimeAccess;
  final Timestamp? subscriptionExpiresAt;
  final Timestamp? subscriptionCancelledAt;
  final String? subscriptionStatus;
  final int? collaboratorLimit;
  final int? activeWorkUsers;

  const Company({
    required this.id,
    required this.companyName,
    required this.email,
    required this.status,
    this.companyCode,
    this.phone,
    this.piva,
    this.website,
    this.referencePerson,
    this.referenceRole,
    this.blockedReason,
    this.blockedAt,
    this.activatedAt,
    this.subscriptionPlan,
    this.lifetimeAccess = false,
    this.subscriptionExpiresAt,
    this.subscriptionCancelledAt,
    this.subscriptionStatus,
    this.collaboratorLimit,
    this.activeWorkUsers,
  });

  factory Company.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Company(
      id: doc.id,
      companyName: data['companyName']?.toString() ?? 'Senza nome',
      email: data['email']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      companyCode: data['companyCode']?.toString(),
      phone: data['phone']?.toString(),
      piva: data['piva']?.toString(),
      website: data['website']?.toString(),
      referencePerson: data['referencePerson']?.toString(),
      referenceRole: data['referenceRole']?.toString(),
      blockedReason: data['blockedReason']?.toString(),
      blockedAt: data['blockedAt'] as Timestamp?,
      activatedAt: data['activatedAt'] as Timestamp?,
      subscriptionPlan: data['subscriptionPlan']?.toString(),
      lifetimeAccess: data['lifetimeAccess'] == true,
      subscriptionExpiresAt: data['subscriptionExpiresAt'] as Timestamp?,
      subscriptionCancelledAt: data['subscriptionCancelledAt'] as Timestamp?,
      subscriptionStatus: data['subscriptionStatus']?.toString(),
      collaboratorLimit: _readIntOrNull(data['collaboratorLimit']),
      activeWorkUsers: _readIntOrNull(data['activeWorkUsers']),
    );
  }

  static int? _readIntOrNull(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }

  Map<String, dynamic> toSubscriptionMap() => {
        'subscriptionPlan': subscriptionPlan,
        'lifetimeAccess': lifetimeAccess,
        'subscriptionExpiresAt': subscriptionExpiresAt,
        'subscriptionCancelledAt': subscriptionCancelledAt,
        'subscriptionStatus': subscriptionStatus,
        'collaboratorLimit': collaboratorLimit,
        'activeWorkUsers': activeWorkUsers,
      };
}
