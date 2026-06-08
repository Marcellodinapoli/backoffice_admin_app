import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../../models/cleanup_result.dart';
import '../../models/dashboard_stats.dart';
import 'firestore_service.dart';

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();
  final _fs = FirestoreService.instance;

  static const cleanupConfirmMessage =
      'Verranno eliminati SOLO:\n'
      '• pendingLogins scaduti (oltre 2 minuti)\n'
      '• documenti nelle collezioni test/debug\n\n'
      'Utenti, aziende, corsi e altri dati reali non verranno toccati.';

  static const obsoleteCollections = [
    'temp',
    'debug',
    'test',
    'old_progress',
    'backup_old',
  ];

  Future<MaintenanceSettings> loadMaintenance() async {
    final doc = await _fs
        .doc(FirestoreCollections.settings, FirestoreCollections.maintenanceDoc)
        .get();
    return MaintenanceSettings.fromMap(doc.data());
  }

  Stream<MaintenanceSettings> watchMaintenance() {
    return _fs
        .doc(FirestoreCollections.settings, FirestoreCollections.maintenanceDoc)
        .snapshots()
        .map((doc) => MaintenanceSettings.fromMap(doc.data()));
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
      'updatedBy': 'backoffice',
    }, SetOptions(merge: true));
  }

  Stream<NotificationSettings> watchNotifications() {
    return _fs
        .doc(
          FirestoreCollections.settings,
          FirestoreCollections.notificationsDoc,
        )
        .snapshots()
        .map((doc) => NotificationSettings.fromMap(doc.data()));
  }

  Future<void> saveNotifications({required bool enabled}) {
    return _fs
        .doc(
          FirestoreCollections.settings,
          FirestoreCollections.notificationsDoc,
        )
        .set({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': 'backoffice',
    }, SetOptions(merge: true));
  }

  DateTime? _parseTimestamp(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  bool _isExpiredPendingLogin(Map<String, dynamic> data, DateTime limit) {
    final createdAt = _parseTimestamp(data['createdAt']);
    if (createdAt == null) return true;
    return createdAt.isBefore(limit);
  }

  Future<int> _deleteQueryDocs(
    Query<Map<String, dynamic>> query, {
    int pageSize = 500,
  }) async {
    var deleted = 0;

    while (true) {
      final snap = await query.limit(pageSize).get();
      if (snap.docs.isEmpty) break;

      final batch = _fs.db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      deleted += snap.docs.length;

      if (snap.docs.length < pageSize) break;
    }

    return deleted;
  }

  Future<int> _cleanupPendingLogins(DateTime limit, List<String> errors) async {
    var deleted = 0;

    try {
      final snap = await _fs.collection(FirestoreCollections.pendingLogins).get();

      for (final doc in snap.docs) {
        if (!_isExpiredPendingLogin(doc.data(), limit)) continue;

        try {
          await doc.reference.delete();
          deleted++;
        } on FirebaseException catch (e) {
          errors.add('pendingLogins/${doc.id}: ${e.code}');
        } catch (e) {
          errors.add('pendingLogins/${doc.id}: $e');
        }
      }
    } on FirebaseException catch (e) {
      errors.add('pendingLogins: ${e.code}');
    } catch (e) {
      errors.add('pendingLogins: $e');
    }

    return deleted;
  }

  Future<int> _cleanupObsoleteCollections(List<String> errors) async {
    var deleted = 0;

    for (final collection in obsoleteCollections) {
      try {
        deleted += await _deleteQueryDocs(_fs.collection(collection));
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') {
          errors.add('$collection: ${e.code}');
        }
      } catch (e) {
        errors.add('$collection: $e');
      }
    }

    return deleted;
  }

  /// Rimuove pendingLogins scaduti e collezioni test/debug.
  Future<CleanupResult> cleanupObsoleteData() async {
    final errors = <String>[];
    final limit = DateTime.now().subtract(const Duration(minutes: 2));

    final pendingLoginsDeleted = await _cleanupPendingLogins(limit, errors);
    final obsoleteDocsDeleted = await _cleanupObsoleteCollections(errors);

    return CleanupResult(
      pendingLoginsDeleted: pendingLoginsDeleted,
      obsoleteDocsDeleted: obsoleteDocsDeleted,
      errors: errors,
    );
  }
}
