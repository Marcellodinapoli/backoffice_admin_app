import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import 'firestore_service.dart';

class JobsService {
  JobsService._();

  static final JobsService instance = JobsService._();
  final _fs = FirestoreService.instance;

  CollectionReference<Map<String, dynamic>> get _jobs =>
      _fs.collection(FirestoreCollections.jobOffers);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllJobs() {
    return _jobs.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCompanyJobs(
    String companyId,
  ) {
    return _jobs
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> approveJob(String jobId) async {
    final now = DateTime.now();
    final expiry = now.add(const Duration(days: 30));

    await _jobs.doc(jobId).update({
      'status': 'approved',
      'online': true,
      'approvedAt': FieldValue.serverTimestamp(),
      'createdAt': Timestamp.fromDate(now),
      'expiryDate': Timestamp.fromDate(expiry),
    });
  }

  Future<void> rejectJob(String jobId) async {
    await _jobs.doc(jobId).update({
      'status': 'rejected',
      'online': false,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockJob(String jobId) async {
    await _jobs.doc(jobId).update({
      'status': 'blocked',
      'online': false,
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockJob(String jobId) async {
    final now = DateTime.now();
    final expiry = now.add(const Duration(days: 30));

    await _jobs.doc(jobId).update({
      'status': 'approved',
      'online': true,
      'unblockedAt': FieldValue.serverTimestamp(),
      'createdAt': Timestamp.fromDate(now),
      'expiryDate': Timestamp.fromDate(expiry),
    });
  }
}

