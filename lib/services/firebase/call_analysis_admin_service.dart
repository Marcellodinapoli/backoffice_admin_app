import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/call_analysis/call_analysis_config_service.dart';

abstract final class CallAnalysisAdminService {
  static Future<void> savePrompt(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw StateError('Inserisci il prompt di sistema.');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance
        .collection('settings')
        .doc(CallAnalysisConfigService.docId)
        .set({
      'prompt': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
      if (uid != null) 'updatedBy': uid,
    }, SetOptions(merge: true));
  }
}
