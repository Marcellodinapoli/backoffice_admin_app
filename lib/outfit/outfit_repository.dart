import 'package:cloud_firestore/cloud_firestore.dart';

import 'outfit_firebase.dart';

class OutfitRepository {
  const OutfitRepository();

  FirebaseFirestore get _db {
    final db = OutfitFirebase.firestore;
    if (db == null || !OutfitFirebase.isAvailable) {
      throw StateError(
        OutfitFirebase.unavailableReason.value ?? 'Outfit non disponibile.',
      );
    }
    return db;
  }

  String? get adminUid => OutfitFirebase.authorizedUid;

  Stream<QuerySnapshot<Map<String, dynamic>>> users() =>
      _db.collection('users').limit(200).snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> user(String uid) =>
      _db.collection('users').doc(uid).snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> usage(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('public_usage')
      .doc('monthly')
      .snapshots();

  Future<void> setUserStatus(String uid, String status) =>
      _db.collection('users').doc(uid).set({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> updateUser({
    required String uid,
    required String plan,
    required String couponCode,
  }) =>
      _db.collection('users').doc(uid).set({
        'subscriptionPlan': plan,
        'couponCode':
            couponCode.trim().isEmpty ? FieldValue.delete() : couponCode.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> resetUsage(String uid) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('public_usage')
        .doc('monthly')
        .delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> consentHistory(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('consents_history')
      .orderBy('acceptedAt', descending: true)
      .limit(100)
      .snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> legal(String id) =>
      _db.collection('settings').doc(id).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> legalVersions(String id) => _db
      .collection('settings')
      .doc(id)
      .collection('versions')
      .orderBy('publishedAt', descending: true)
      .limit(50)
      .snapshots();

  Future<Map<String, dynamic>?> legalVersion(String id, String version) async =>
      (await _db
              .collection('settings')
              .doc(id)
              .collection('versions')
              .doc(version)
              .get())
          .data();

  Future<void> publishLegal({
    required String id,
    required String version,
    required String title,
    required Map<String, String> content,
  }) async {
    final root = _db.collection('settings').doc(id);
    final batch = _db.batch();
    batch.set(root, {
      'activeVersion': version,
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(root.collection('versions').doc(version), {
      'version': version,
      'title': title,
      'content': content,
      'publishedAt': FieldValue.serverTimestamp(),
      'updatedBy': adminUid,
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> coupons() =>
      _db.collection('coupons').limit(100).snapshots();

  Future<void> saveCoupon(String code, Map<String, dynamic> values) =>
      _db.collection('coupons').doc(normalizeCoupon(code)).set({
        ...values,
        'targetAudience': 'users',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminUid,
      }, SetOptions(merge: true));

  Future<void> deleteCoupon(String code) =>
      _db.collection('coupons').doc(normalizeCoupon(code)).delete();

  String normalizeCoupon(String code) =>
      code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  Stream<DocumentSnapshot<Map<String, dynamic>>> plans() => _db
      .collection('settings')
      .doc('moodfit_plan_limits')
      .snapshots();

  Future<void> savePlans(Map<String, dynamic> plans) => _db
      .collection('settings')
      .doc('moodfit_plan_limits')
      .set({
        'plans': plans,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminUid,
      });

  Stream<DocumentSnapshot<Map<String, dynamic>>> prompt(String id) =>
      _db.collection('settings').doc(id).snapshots();

  Future<void> savePrompt({
    required String id,
    required String prompt,
    required int version,
  }) =>
      _db.collection('settings').doc(id).set({
        'prompt': prompt,
        'version': version,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminUid,
      }, SetOptions(merge: true));
}
