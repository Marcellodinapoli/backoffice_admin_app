import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../../models/company.dart';
import 'firestore_service.dart';

class CompaniesService {
  CompaniesService._();

  static final CompaniesService instance = CompaniesService._();
  final _fs = FirestoreService.instance;

  Stream<List<Company>> watchAll() {
    return _fs.collection(FirestoreCollections.companies).snapshots().map(
          (snap) =>
              snap.docs.map((d) => Company.fromFirestore(d)).toList(),
        );
  }

  Stream<Company?> watchCompany(String companyId) {
    return _fs
        .doc(FirestoreCollections.companies, companyId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Company.fromFirestore(doc);
    });
  }

  Stream<String?> watchLinkedUserStatus(String companyId) {
    return _fs.doc(FirestoreCollections.users, companyId).snapshots().map(
          (doc) => doc.data()?['status']?.toString(),
        );
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      watchLinkedWorkUsers(String companyCode) {
    return _fs
        .collection(FirestoreCollections.users)
        .where('companyCode', isEqualTo: companyCode)
        .snapshots()
        .map((snap) => snap.docs);
  }

  Future<void> blockCompany(
    String companyId,
    String companyCode,
    String reason,
  ) async {
    await _fs.doc(FirestoreCollections.companies, companyId).update({
      'status': 'blocked',
      'blockedReason': reason,
      'blockedAt': FieldValue.serverTimestamp(),
    });

    final users = await _fs
        .collection(FirestoreCollections.users)
        .where('companyCode', isEqualTo: companyCode)
        .get();

    final batch = _fs.db.batch();
    for (final doc in users.docs) {
      batch.update(doc.reference, {'status': 'blocked'});
    }
    await batch.commit();
  }

  Future<void> activateCompany(String companyId, String companyCode) async {
    await _fs.doc(FirestoreCollections.companies, companyId).update({
      'status': 'active',
      'blockedReason': FieldValue.delete(),
      'blockedAt': FieldValue.delete(),
      'activatedAt': FieldValue.serverTimestamp(),
    });

    final users = await _fs
        .collection(FirestoreCollections.users)
        .where('companyCode', isEqualTo: companyCode)
        .get();

    final batch = _fs.db.batch();
    for (final doc in users.docs) {
      batch.update(doc.reference, {'status': 'active'});
    }
    await batch.commit();
  }
}
