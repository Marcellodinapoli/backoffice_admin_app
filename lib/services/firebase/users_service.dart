import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../../core/constants/user_account_status.dart';
import '../../models/app_user.dart';
import 'firestore_service.dart';

class UsersService {
  UsersService._();

  static final UsersService instance = UsersService._();
  final _fs = FirestoreService.instance;

  Stream<List<AppUser>> watchByType(String type) {
    return _fs
        .collection(FirestoreCollections.users)
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppUser.fromFirestore(d)).toList());
  }

  Stream<AppUser?> watchUser(String userId) {
    return _fs.doc(FirestoreCollections.users, userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  Future<void> updateField(String userId, String field, dynamic value) {
    return _fs.doc(FirestoreCollections.users, userId).update({field: value});
  }

  Future<void> blockUser(String userId, String reason) {
    return _fs.doc(FirestoreCollections.users, userId).update({
      'status': 'blocked',
      'blockedReason': reason,
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> standbyUser(String userId, String reason) {
    return _fs.doc(FirestoreCollections.users, userId).update({
      'status': 'standby',
      'standbyReason': reason,
      'standbyAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> activateUser(String userId) {
    return _fs
        .doc(FirestoreCollections.users, userId)
        .update(UserAccountStatus.activationUpdate());
  }

  Future<void> toggleType(String userId, String currentType) async {
    final newType = currentType == 'work' ? 'public' : 'work';
    if (newType == 'work') {
      await _fs.doc(FirestoreCollections.users, userId).update({
        'type': newType,
        'status': UserAccountStatus.workRegistrationStatus,
      });
      return;
    }
    await updateField(userId, 'type', newType);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getCompany(
      String? companyId) async {
    if (companyId == null) return null;
    final doc =
        await _fs.doc(FirestoreCollections.companies, companyId).get();
    return doc.exists ? doc : null;
  }
}
