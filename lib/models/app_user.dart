import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/user_account_status.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String type;
  final String status;
  final String? workRole;
  final String? companyId;
  final String? companyCode;
  final String? blockedReason;
  final String? standbyReason;
  final Timestamp? createdAt;
  final Timestamp? lastLoginAt;
  final Timestamp? blockedAt;
  final Timestamp? standbyAt;
  final String? subscriptionPlan;
  final bool lifetimeAccess;
  final Timestamp? subscriptionExpiresAt;
  final String? subscriptionStatus;
  final Timestamp? subscriptionCancelledAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.status,
    this.workRole,
    this.companyId,
    this.companyCode,
    this.blockedReason,
    this.standbyReason,
    this.createdAt,
    this.lastLoginAt,
    this.blockedAt,
    this.standbyAt,
    this.subscriptionPlan,
    this.lifetimeAccess = false,
    this.subscriptionExpiresAt,
    this.subscriptionStatus,
    this.subscriptionCancelledAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final type = data['type']?.toString() ?? 'public';
    return AppUser(
      id: doc.id,
      name: data['name']?.toString() ?? 'Senza nome',
      email: data['email']?.toString() ?? '',
      type: type,
      status: data['status']?.toString() ??
          UserAccountStatus.defaultRawStatus(type),
      workRole: data['workRole']?.toString(),
      companyId: data['companyId']?.toString(),
      companyCode: data['companyCode']?.toString(),
      blockedReason: data['blockedReason']?.toString(),
      standbyReason: data['standbyReason']?.toString(),
      createdAt: data['createdAt'] as Timestamp?,
      lastLoginAt: data['lastLoginAt'] as Timestamp?,
      blockedAt: data['blockedAt'] as Timestamp?,
      standbyAt: data['standbyAt'] as Timestamp?,
      subscriptionPlan: data['subscriptionPlan']?.toString(),
      lifetimeAccess: data['lifetimeAccess'] == true,
      subscriptionExpiresAt: data['subscriptionExpiresAt'] as Timestamp?,
      subscriptionStatus: data['subscriptionStatus']?.toString(),
      subscriptionCancelledAt: data['subscriptionCancelledAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> get subscriptionData => {
        'subscriptionPlan': subscriptionPlan ?? 'free',
        if (lifetimeAccess) 'lifetimeAccess': true,
        if (subscriptionExpiresAt != null)
          'subscriptionExpiresAt': subscriptionExpiresAt,
        if (subscriptionStatus != null) 'subscriptionStatus': subscriptionStatus,
        if (subscriptionCancelledAt != null)
          'subscriptionCancelledAt': subscriptionCancelledAt,
      };

  String get displayStatus =>
      UserAccountStatus.displayStatus(status, type: type);

  bool get needsAdminActivation =>
      UserAccountStatus.needsAdminActivation(status, type: type);

  String get workRoleLabel {
    switch (workRole) {
      case 'supervisor':
        return 'Supervisor';
      case 'collaborator':
        return 'Collaboratore';
      default:
        return 'N/D';
    }
  }
}
