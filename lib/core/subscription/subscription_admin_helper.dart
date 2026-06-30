import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:credit_calc_core/credit_calc_core.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/company.dart';
import '../../services/firebase/companies_service.dart';

/// Soglia unica di avviso utilizzo piano (allineata a CreditCalc: 80%).
const double subscriptionLimitWarningRatio = 0.8;

class SubscriptionCardInfo {
  final String planLabel;
  final String expiryLabel;
  final int? used;
  final int? limit;
  final bool unlimited;
  final String limitLabel;
  final bool usageReady;

  const SubscriptionCardInfo({
    required this.planLabel,
    required this.expiryLabel,
    this.used,
    this.limit,
    this.unlimited = false,
    this.limitLabel = 'Utilizzo limite',
    this.usageReady = false,
  });

  double? get ratio {
    if (unlimited || limit == null || limit! <= 0) return null;
    return ((used ?? 0) / limit!).clamp(0.0, 1.0);
  }

  /// Percentuale utilizzo limite (0–100+), per lista utenti BackOffice.
  int? get usagePercent {
    final r = ratio;
    if (r == null) return null;
    return (r * 100).round();
  }

  bool get nearLimit {
    final r = ratio;
    return r != null && r >= subscriptionLimitWarningRatio;
  }

  bool get atLimit {
    final r = ratio;
    return r != null && r >= 1.0;
  }
}

abstract final class SubscriptionAdminHelper {
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  static String planLabel(String? planId) {
    return switch ((planId ?? 'free').toLowerCase()) {
      'plus' => 'Plus',
      'enterprise' || 'azienda' => 'Enterprise',
      'starter' => 'Starter',
      'business' => 'Business',
      'professional' => 'Professional',
      'free' => 'Gratis',
      _ => planId ?? 'Gratis',
    };
  }

  static String _normalizePublicPlanId(String planId) =>
      switch (planId.toLowerCase()) {
        'plus' => 'plus',
        'enterprise' => 'enterprise',
        _ => 'free',
      };

  /// Piano individuale con fair use da BackOffice (`settings/plan_limits`).
  static bool isUnlimitedPublicPlan(String planId) {
    final limits = publicPlanLimitsForPlan(_normalizePublicPlanId(planId));
    return limits.enforcement == PublicPlanEnforcement.fairUse;
  }

  /// Riga piano in lista utenti: null se FREE con limiti hard; "Senza limiti" se fair use.
  static String? publicUserListPlanLine(AppUser user) {
    return publicUserListPlanLineFromData(
      user.subscriptionData,
      type: user.type,
    );
  }

  static String? publicUserListPlanLineFromData(
    Map<String, dynamic> data, {
    required String type,
  }) {
    if (type != 'public') return null;
    final planId = data['subscriptionPlan']?.toString() ?? 'free';
    if (data['lifetimeAccess'] == true || isUnlimitedPublicPlan(planId)) {
      return 'Senza limiti';
    }
    if (_normalizePublicPlanId(planId) != 'free') {
      return 'Piano: ${planLabel(planId)}';
    }
    return null;
  }

  static String? _companyPlanConfigId(String planId) {
    return switch (planId.toLowerCase()) {
      'free' => 'free',
      'plus' => 'plus',
      'enterprise' || 'azienda' => 'enterprise',
      _ => null,
    };
  }

  static int companyCollaboratorLimit(String planId, [int? stored]) {
    if (stored != null && stored > 0) return stored;
    return switch (planId.toLowerCase()) {
      'starter' || 'plus' => 10,
      'business' => 25,
      'professional' => 50,
      'enterprise' || 'azienda' => 100,
      _ => 2,
    };
  }

  static SubscriptionCardInfo fromCompanyMap(Map<String, dynamic> data) {
    final planId = (data['subscriptionPlan'] ?? 'free').toString();
    final active = _readInt(data['activeWorkUsers']);

    if (data['lifetimeAccess'] == true) {
      return SubscriptionCardInfo(
        planLabel: planLabel(planId),
        expiryLabel: _expiryLabel(data),
        used: active,
        unlimited: true,
        limitLabel: 'Collaboratori attivi',
      );
    }

    final configPlanId = _companyPlanConfigId(planId);
    if (configPlanId != null && isUnlimitedPublicPlan(configPlanId)) {
      return SubscriptionCardInfo(
        planLabel: planLabel(planId),
        expiryLabel: _expiryLabel(data),
        used: active,
        unlimited: true,
        limitLabel: 'Collaboratori attivi',
      );
    }

    final limit = companyCollaboratorLimit(
      planId,
      _readIntOrNull(data['collaboratorLimit']),
    );

    return SubscriptionCardInfo(
      planLabel: planLabel(planId),
      expiryLabel: _expiryLabel(data),
      used: active,
      limit: limit,
      limitLabel: 'Collaboratori attivi',
    );
  }

  static Future<SubscriptionCardInfo> loadCompanyUsage(Company company) async {
    final info = fromCompanyMap(company.toSubscriptionMap());
    if (info.unlimited) return info;

    try {
      final active = await CompaniesService.instance.countLinkedWorkUsers(
        companyId: company.id,
        companyCode: company.companyCode,
      );
      return SubscriptionCardInfo(
        planLabel: info.planLabel,
        expiryLabel: info.expiryLabel,
        used: active,
        limit: info.limit,
        limitLabel: info.limitLabel,
        usageReady: true,
      );
    } catch (_) {
      return info;
    }
  }

  static SubscriptionCardInfo fromPublicUserMap(Map<String, dynamic> data) {
    final planId = (data['subscriptionPlan'] ?? 'free').toString();
    if (data['lifetimeAccess'] == true || isUnlimitedPublicPlan(planId)) {
      return SubscriptionCardInfo(
        planLabel: planLabel(planId),
        expiryLabel: _expiryLabel(data),
        unlimited: true,
        limitLabel: 'Utilizzo piano',
        usageReady: true,
      );
    }

    final primary = _primaryPublicLimit(planId);
    return SubscriptionCardInfo(
      planLabel: planLabel(planId),
      expiryLabel: _expiryLabel(data),
      limitLabel: primary?.label ?? 'Utilizzo piano',
    );
  }

  static ({int limit, String label})? _primaryPublicLimit(String planId) {
    final limits = _publicLimits(planId);
    if (limits.isEmpty) return null;

    var maxLimit = 1;
    for (final entry in limits.entries) {
      if (entry.value <= 0) continue;
      if (entry.value >= maxLimit) maxLimit = entry.value;
    }
    return (limit: maxLimit, label: 'Utilizzo piano');
  }

  static Future<SubscriptionCardInfo> loadPublicUsage(
    AppUser user, {
    bool summaryOnly = false,
  }) async {
    final data = user.subscriptionData;
    final planId = (data['subscriptionPlan'] ?? 'free').toString();

    if (data['lifetimeAccess'] == true || isUnlimitedPublicPlan(planId)) {
      return SubscriptionCardInfo(
        planLabel: planLabel(planId),
        expiryLabel: _expiryLabel(data),
        unlimited: true,
        limitLabel: 'Utilizzo piano',
        usageReady: true,
      );
    }

    final limits = summaryOnly
        ? Map<String, int>.fromEntries(
            _publicLimits(planId)
                .entries
                .where((e) => e.key != 'activeCourses'),
          )
        : _publicLimits(planId);
    if (limits.isEmpty) {
      return SubscriptionCardInfo(
        planLabel: planLabel(planId),
        expiryLabel: _expiryLabel(data),
        unlimited: true,
        limitLabel: 'Utilizzo piano',
        usageReady: true,
      );
    }

    final userId = user.id;
    DocumentSnapshot<Map<String, dynamic>> monthlySnap;
    int activeCourses = 0;
    try {
      const serverGet = GetOptions(source: Source.server);
      if (summaryOnly) {
        monthlySnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('public_usage')
            .doc('monthly')
            .get(serverGet);
      } else {
        final needsCourses = limits.containsKey('activeCourses');
        final results = await Future.wait([
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('public_usage')
              .doc('monthly')
              .get(serverGet),
          if (needsCourses)
            _countActiveCourses(userId)
          else
            Future<int>.value(0),
        ]);
        monthlySnap = results[0] as DocumentSnapshot<Map<String, dynamic>>;
        activeCourses = needsCourses ? results[1] as int : 0;
      }
    } catch (_) {
      return fromPublicUserMap(data);
    }

    final monthly = monthlySnap.data() ?? {};
    final monthKey = _monthKey();
    final counts = monthly['monthKey'] == monthKey
        ? Map<String, dynamic>.from(
            (monthly['counts'] as Map?)?.cast<String, dynamic>() ?? {},
          )
        : <String, dynamic>{};

    var maxUsed = 0;
    var maxLimit = 0;
    var maxRatio = -1.0;
    for (final entry in limits.entries) {
      final used = entry.key == 'activeCourses'
          ? activeCourses
          : _readInt(counts[entry.key]);
      if (entry.value <= 0) continue;
      final ratio = used / entry.value;
      if (ratio > maxRatio) {
        maxRatio = ratio;
        maxUsed = used;
        maxLimit = entry.value;
      }
    }

    if (maxLimit <= 0) {
      final fallbackLimit = limits.values.where((v) => v > 0).fold(0, (a, b) => a > b ? a : b);
      if (fallbackLimit <= 0) {
        return SubscriptionCardInfo(
          planLabel: planLabel(planId),
          expiryLabel: _expiryLabel(data),
          unlimited: true,
          limitLabel: 'Utilizzo piano',
          usageReady: true,
        );
      }
      maxLimit = fallbackLimit;
      maxUsed = 0;
    }

    return SubscriptionCardInfo(
      planLabel: planLabel(planId),
      expiryLabel: _expiryLabel(data),
      used: maxUsed,
      limit: maxLimit,
      limitLabel: 'Utilizzo piano',
      usageReady: true,
    );
  }

  static Future<SubscriptionCardInfo> loadPublicUsageById(String userId) async {
    final userSnap =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = userSnap.data() ?? {};
    return loadPublicUsage(_appUserFromData(userId, data));
  }

  static AppUser _appUserFromData(String userId, Map<String, dynamic> data) {
    return AppUser(
      id: userId,
      name: data['name']?.toString() ?? 'Senza nome',
      email: data['email']?.toString() ?? '',
      type: data['type']?.toString() ?? 'public',
      status: data['status']?.toString() ?? 'active',
      subscriptionPlan: data['subscriptionPlan']?.toString(),
      lifetimeAccess: data['lifetimeAccess'] == true,
      subscriptionExpiresAt: data['subscriptionExpiresAt'] as Timestamp?,
      subscriptionStatus: data['subscriptionStatus']?.toString(),
      subscriptionCancelledAt: data['subscriptionCancelledAt'] as Timestamp?,
    );
  }

  static String _expiryLabel(Map<String, dynamic> data) {
    if (data['lifetimeAccess'] == true) return 'Non scade';

    final expires = data['subscriptionExpiresAt'];
    if (expires is Timestamp) {
      return 'Scade il ${_dateFmt.format(expires.toDate())}';
    }

    final status = (data['subscriptionStatus'] ?? 'active').toString();
    if (status == 'cancelled') {
      final cancelled = data['subscriptionCancelledAt'];
      if (cancelled is Timestamp) {
        return 'Annullato il ${_dateFmt.format(cancelled.toDate())}';
      }
      return 'Annullato';
    }
    if (status == 'pending') return 'In attivazione';

    final plan = (data['subscriptionPlan'] ?? 'free').toString();
    if (plan == 'free') return 'Senza scadenza';

    return '—';
  }

  static Map<String, int> _publicLimits(String planId) {
    final limits = publicPlanLimitsForPlan(planId);
    if (limits.enforcement == PublicPlanEnforcement.fairUse) {
      return const {};
    }
    return {
      if (limits.activeCourses != null) 'activeCourses': limits.activeCourses!,
      if (limits.monthlyQuiz != null) 'quiz': limits.monthlyQuiz!,
      if (limits.monthlyWarmup != null) 'warmup': limits.monthlyWarmup!,
      if (limits.monthlyRoleplay != null) 'roleplay': limits.monthlyRoleplay!,
      if (limits.monthlyContestation != null)
        'contestation': limits.monthlyContestation!,
      if (limits.monthlyRepaymentPlan != null)
        'repaymentPlan': limits.monthlyRepaymentPlan!,
      if (limits.monthlyBalanceWriteOff != null)
        'balanceWriteOff': limits.monthlyBalanceWriteOff!,
      if (limits.monthlyItinerary != null) 'itinerary': limits.monthlyItinerary!,
      if (limits.monthlyJobApplications != null)
        'jobApplication': limits.monthlyJobApplications!,
    };
  }

  static Future<int> _countActiveCourses(String userId) async {
    final snap = await FirebaseFirestore.instance
        .collection('userProgress')
        .doc(userId)
        .collection('courses')
        .get(const GetOptions(source: Source.server));
    var active = 0;
    for (final doc in snap.docs) {
      final progress = doc.data()['progress'];
      final p = progress is num ? progress.toInt() : 0;
      if (p < 100) active++;
    }
    return active;
  }

  static String _monthKey([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  static int _readInt(dynamic raw, [int fallback = 0]) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return fallback;
  }

  static int? _readIntOrNull(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }
}
