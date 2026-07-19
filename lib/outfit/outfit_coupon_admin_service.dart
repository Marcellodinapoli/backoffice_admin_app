import 'package:cloud_firestore/cloud_firestore.dart';

import 'outfit_firebase.dart';

class OutfitCouponRecord {
  final String code;
  final bool enabled;
  final int usedCount;
  final int? maxUses;
  final DateTime? expiresAt;
  final DateTime? benefitExpiresAt;
  final String? plan;
  final String? label;
  final DateTime? createdAt;

  const OutfitCouponRecord({
    required this.code,
    required this.enabled,
    required this.usedCount,
    this.maxUses,
    this.expiresAt,
    this.benefitExpiresAt,
    this.plan,
    this.label,
    this.createdAt,
  });

  factory OutfitCouponRecord.fromDoc(String id, Map<String, dynamic> data) {
    final expires = data['expiresAt'];
    final benefitExpires = data['benefitExpiresAt'];
    final created = data['createdAt'];
    final maxUsesRaw = data['maxUses'];
    final usedRaw = data['usedCount'];
    final planRaw = (data['plan'] ?? data['tier'] ?? '').toString().trim();

    return OutfitCouponRecord(
      code: id,
      enabled: data['enabled'] == true || data['active'] == true,
      usedCount: usedRaw is int
          ? usedRaw
          : usedRaw is num
              ? usedRaw.toInt()
              : 0,
      maxUses: maxUsesRaw is int
          ? maxUsesRaw
          : maxUsesRaw is num
              ? maxUsesRaw.toInt()
              : null,
      expiresAt: expires is Timestamp ? expires.toDate() : null,
      benefitExpiresAt:
          benefitExpires is Timestamp ? benefitExpires.toDate() : null,
      plan: planRaw.isEmpty ? null : planRaw,
      label: (data['label'] ?? '').toString().trim().isEmpty
          ? null
          : (data['label'] ?? '').toString(),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  bool get exhausted =>
      maxUses != null && maxUses! > 0 && usedCount >= maxUses!;

  bool get expired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

abstract final class OutfitCouponAdminService {
  static CollectionReference<Map<String, dynamic>> get _col {
    final db = OutfitFirebase.firestore;
    if (db == null) {
      throw StateError('Firebase Outfit non disponibile.');
    }
    return db.collection('coupons');
  }

  static String normalizeCode(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  static Stream<List<OutfitCouponRecord>> watchCoupons() {
    return _col.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => OutfitCouponRecord.fromDoc(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final ac = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bc = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bc.compareTo(ac);
      });
      return list;
    });
  }

  static Future<void> createCoupon({
    required String code,
    String? label,
    int? maxUses,
    DateTime? expiresAt,
    required DateTime benefitExpiresAt,
    String? restrictedPlan,
  }) async {
    final normalized = normalizeCode(code);
    if (normalized.isEmpty) {
      throw ArgumentError('Codice coupon obbligatorio');
    }

    final existing = await _col.doc(normalized).get();
    if (existing.exists) {
      throw StateError('Esiste già un coupon con questo codice.');
    }

    final uid = OutfitFirebase.auth?.currentUser?.uid;
    final benefitEnd = endOfDay(benefitExpiresAt);
    final plan = restrictedPlan?.trim().toLowerCase();
    final hasPlan = plan != null && plan.isNotEmpty;

    await _col.doc(normalized).set({
      'enabled': true,
      'active': true,
      'type': 'reset_limits',
      'targetAudience': 'users',
      'lifetimeFree': false,
      'usedCount': 0,
      'benefitExpiresAt': Timestamp.fromDate(benefitEnd),
      if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
      if (maxUses != null && maxUses > 0) 'maxUses': maxUses,
      if (expiresAt != null)
        'expiresAt': Timestamp.fromDate(endOfDay(expiresAt)),
      if (hasPlan) 'plan': plan,
      if (hasPlan) 'tier': plan,
      'createdAt': FieldValue.serverTimestamp(),
      if (uid != null) 'createdBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setEnabled({
    required String code,
    required bool enabled,
  }) async {
    final normalized = normalizeCode(code);
    await _col.doc(normalized).set(
      {
        'enabled': enabled,
        'active': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> updateCoupon({
    required String code,
    String? label,
    int? maxUses,
    bool clearMaxUses = false,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    required DateTime benefitExpiresAt,
    String? restrictedPlan,
    bool clearPlan = false,
  }) async {
    final normalized = normalizeCode(code);
    final snap = await _col.doc(normalized).get();
    if (!snap.exists) {
      throw StateError('Coupon non trovato.');
    }

    final updates = <String, dynamic>{
      'benefitExpiresAt': Timestamp.fromDate(endOfDay(benefitExpiresAt)),
      'lifetimeFree': false,
      'targetAudience': 'users',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final trimmedLabel = label?.trim() ?? '';
    if (trimmedLabel.isNotEmpty) {
      updates['label'] = trimmedLabel;
    } else {
      updates['label'] = FieldValue.delete();
    }

    if (maxUses != null && maxUses > 0) {
      updates['maxUses'] = maxUses;
    } else if (clearMaxUses) {
      updates['maxUses'] = FieldValue.delete();
    }

    if (expiresAt != null) {
      updates['expiresAt'] = Timestamp.fromDate(endOfDay(expiresAt));
    } else if (clearExpiresAt) {
      updates['expiresAt'] = FieldValue.delete();
    }

    if (restrictedPlan != null && restrictedPlan.trim().isNotEmpty) {
      final plan = restrictedPlan.trim().toLowerCase();
      updates['plan'] = plan;
      updates['tier'] = plan;
    } else if (clearPlan) {
      updates['plan'] = FieldValue.delete();
      updates['tier'] = FieldValue.delete();
    }

    await _col.doc(normalized).set(updates, SetOptions(merge: true));
  }

  static Future<void> deleteCoupon(String code) async {
    final normalized = normalizeCode(code);
    if (normalized.isEmpty) {
      throw ArgumentError('Codice coupon non valido.');
    }
    await _col.doc(normalized).delete();
  }
}

String outfitCouponPlanLabel(String? planId) {
  switch (planId?.toLowerCase()) {
    case 'free':
      return 'Gratis';
    case 'plus':
      return 'Plus';
    case 'pro':
      return 'Pro';
    default:
      return planId ?? '';
  }
}
