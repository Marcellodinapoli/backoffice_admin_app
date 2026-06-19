import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import 'firestore_service.dart';

class VersionedSettingsDocument {
  const VersionedSettingsDocument({
    required this.text,
    required this.version,
  });

  final String text;
  final String version;
}

class VersionedSettingsService {
  VersionedSettingsService._();

  static final VersionedSettingsService instance = VersionedSettingsService._();
  final _fs = FirestoreService.instance;

  Future<VersionedSettingsDocument> load({
    required String docId,
    String defaultVersion = '1.0.0',
  }) async {
    final snap = await _fs
        .doc(FirestoreCollections.settings, docId)
        .get();

    if (!snap.exists) {
      return VersionedSettingsDocument(text: '', version: defaultVersion);
    }

    final data = snap.data() ?? {};
    return VersionedSettingsDocument(
      text: (data['text'] ?? '').toString(),
      version: (data['version'] ?? defaultVersion).toString(),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchVersions(String docId) {
    return _fs
        .doc(FirestoreCollections.settings, docId)
        .collection('versions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> saveNewVersion({
    required String docId,
    required String text,
    required String newVersion,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final settingsRef =
        _fs.doc(FirestoreCollections.settings, docId);

    batch.set(
      settingsRef.collection('versions').doc(newVersion),
      {
        'text': text,
        'version': newVersion,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    batch.set(settingsRef, {
      'text': text,
      'version': newVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
