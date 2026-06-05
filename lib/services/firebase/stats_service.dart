import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../../models/dashboard_stats.dart';
import 'firestore_service.dart';

class StatsService {
  StatsService._();

  static final StatsService instance = StatsService._();
  final _fs = FirestoreService.instance;

  Future<DashboardStats> loadStats() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final usersCol = _fs.collection(FirestoreCollections.users);
    final jobsCol = _fs.collection(FirestoreCollections.jobOffers);

    final results = await Future.wait([
      usersCol.count().get(),
      usersCol.where('status', isEqualTo: 'active').count().get(),
      usersCol.where('status', isEqualTo: 'blocked').count().get(),
      usersCol
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .count()
          .get(),
      _fs.collection(FirestoreCollections.companies).count().get(),
      _fs.collection(FirestoreCollections.courses).count().get(),
      jobsCol.count().get(),
      jobsCol
          .where('status', isEqualTo: 'approved')
          .where('online', isEqualTo: true)
          .count()
          .get(),
      jobsCol.where('status', isEqualTo: 'pending').count().get(),
      _fs.collection(FirestoreCollections.jobApplications).count().get(),
      _fs.collection(FirestoreCollections.roleplay).count().get(),
    ]);

    return DashboardStats(
      totalUsers: results[0].count ?? 0,
      activeUsers: results[1].count ?? 0,
      blockedUsers: results[2].count ?? 0,
      newUsersThisMonth: results[3].count ?? 0,
      totalCompanies: results[4].count ?? 0,
      totalCourses: results[5].count ?? 0,
      totalJobOffers: results[6].count ?? 0,
      activeJobOffers: results[7].count ?? 0,
      pendingJobOffers: results[8].count ?? 0,
      totalApplications: results[9].count ?? 0,
      totalRoleplay: results[10].count ?? 0,
    );
  }
}
