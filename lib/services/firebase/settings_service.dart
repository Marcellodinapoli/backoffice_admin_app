import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../../models/dashboard_stats.dart';
import 'firestore_service.dart';

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();
  final _fs = FirestoreService.instance;

  Future<MaintenanceSettings> loadMaintenance() async {
    final doc = await _fs
        .doc(FirestoreCollections.settings, FirestoreCollections.maintenanceDoc)
        .get();
    return MaintenanceSettings.fromMap(doc.data());
  }

  Future<void> saveMaintenance({
    required bool enabled,
    required String section,
  }) {
    return _fs
        .doc(FirestoreCollections.settings, FirestoreCollections.maintenanceDoc)
        .set({
      'section': section,
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> cleanupObsoleteData() async {
    int deletedCount = 0;
    final now = DateTime.now();
    final limit = now.subtract(const Duration(minutes: 2));

    final pendingSnap =
        await _fs.collection(FirestoreCollections.pendingLogins).get();
    for (final doc in pendingSnap.docs) {
      final createdAt = doc.data()['createdAt'];
      if (createdAt is Timestamp && createdAt.toDate().isBefore(limit)) {
        await doc.reference.delete();
        deletedCount++;
      }
    }

    const obsolete = ['temp', 'debug', 'test', 'old_progress', 'backup_old'];
    for (final col in obsolete) {
      final snap = await _fs.collection(col).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
        deletedCount++;
      }
    }

    return deletedCount;
  }
}
