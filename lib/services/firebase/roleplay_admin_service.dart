import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/roleplay/roleplay_config_service.dart';

abstract final class RoleplayAdminService {
  static Future<void> saveSimulationPrompt(
    String simulationId,
    String prompt,
  ) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw StateError('Inserisci il prompt di sistema.');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance
        .collection(RoleplayConfigService.collection)
        .doc(simulationId)
        .set({
      RoleplayConfigService.promptField: trimmed,
      RoleplayConfigService.legacyGptPromptField: trimmed,
      RoleplayConfigService.aiProviderField: RoleplayConfigService.openAiProvider,
      'updatedAt': FieldValue.serverTimestamp(),
      if (uid != null) 'updatedBy': uid,
    }, SetOptions(merge: true));
  }
}
