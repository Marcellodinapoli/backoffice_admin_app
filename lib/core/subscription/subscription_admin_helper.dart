import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Soglia unica di avviso utilizzo piano (allineata a CreditCalc: 80%).
const double subscriptionLimitWarningRatio = 0.8;

class SubscriptionCardInfo {
  final String planLabel;
  final String expiryLabel;
  final int? used;
  final int? limit;
  final bool unlimited;
  final String limitLabel;

  const SubscriptionCardInfo({
    required this.planLabel,
    required this.expiryLabel,
    this.used,
    this.limit,
    this.unlimited = false,
    this.limitLabel = 'Utilizzo limite',
  });

  double? get ratio {
    if (unlimited || limit == null || limit! <= 0) return null;
    return ((used ?? 0) / limit!).clamp(0.0, 1.0);
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

  static SubscriptionCardInfo fromPublicUserMap(Map<String, dynamic> data) {
    final planId = (data['subscriptionPlan'] ?? 'free').toString();
    if (planId == 'enterprise') {
      return SubscriptionCardInfo(
        planLabel: planLabel(planId),
        expiryLabel: _expiryLabel(data),
        unlimited: true,
        limitLabel: 'Utilizzo piano',
      );
    }

    return SubscriptionCardInfo(
      planLabel: planLabel(planId),
      expiryLabel: _expiryLabel(data),
      limitLabel: 'Utilizzo piano',
    );
  }

  static Future<SubscriptionCardInfo> loadPublicUsage(String userId) async {
    final userSnap =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = userSnap.data() ?? {};
    final planId = (data['subscriptionPlan'] ?? 'free').toString();

    if (planId == 'enterprise' || data['lifetimeAccess'] == true) {
      return SubscriptionCardInfo(
        planLabel: planLabel(planId),
        expiryLabel: _expiryLabel(data),
        unlimited: true,
        limitLabel: 'Utilizzo piano',
      );
    }

    final limits = _publicLimits(planId);
    final monthlySnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('public_usage')
        .doc('monthly')
        .get();
    final monthly = monthlySnap.data() ?? {};
    final monthKey = _monthKey();
    final counts = monthly['monthKey'] == monthKey
        ? Map<String, dynamic>.from(
            (monthly['counts'] as Map?)?.cast<String, dynamic>() ?? {},
          )
        : <String, dynamic>{};

    var maxUsed = 0;
    var maxLimit = 1;
    for (final entry in limits.entries) {
      final used = entry.key == 'activeCourses'
          ? await _countActiveCourses(userId)
          : _readInt(counts[entry.key]);
      if (entry.value <= 0) continue;
      if (used > maxUsed || (used / entry.value) > (maxUsed / maxLimit)) {
        maxUsed = used;
        maxLimit = entry.value;
      }
    }

    return SubscriptionCardInfo(
      planLabel: planLabel(planId),
      expiryLabel: _expiryLabel(data),
      used: maxUsed,
      limit: maxLimit,
      limitLabel: 'Utilizzo piano',
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
    if (planId == 'plus') {
      return const {
        'activeCourses': 50,
        'quiz': 200,
        'warmup': 100,
        'roleplay': 80,
        'contestation': 50,
        'repaymentPlan': 20,
        'balanceWriteOff': 15,
        'itinerary': 20,
        'jobApplication': 50,
      };
    }
    return const {
      'activeCourses': 3,
      'quiz': 10,
      'warmup': 5,
      'roleplay': 2,
      'contestation': 3,
      'repaymentPlan': 1,
      'balanceWriteOff': 1,
      'itinerary': 2,
      'jobApplication': 3,
    };
  }

  static Future<int> _countActiveCourses(String userId) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('course_progress')
        .where('status', isEqualTo: 'active')
        .get();
    return snap.size;
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
