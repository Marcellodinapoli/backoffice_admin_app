import '../../core/constants/firestore_collections.dart';
import '../../core/roleplay/roleplay_config_service.dart';
import '../../models/roleplay_simulation.dart';
import 'firestore_service.dart';

class RoleplayService {
  RoleplayService._();

  static final RoleplayService instance = RoleplayService._();
  final _fs = FirestoreService.instance;

  Stream<List<RoleplaySimulation>> watchByCategory(String category) {
    return _fs
        .collection(FirestoreCollections.roleplay)
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RoleplaySimulation.fromFirestore(
                  d.id,
                  d.data(),
                ))
            .toList());
  }

  Future<void> updateAiProvider(String simulationId, String provider) {
    return _fs.doc(FirestoreCollections.roleplay, simulationId).update({
      'aiProvider': provider,
    });
  }

  Future<void> updateSimulation({
    required String id,
    required String title,
    required String category,
    required String prompt,
    required List<Map<String, String>> practiceData,
    required String difficulty,
    required String personality,
  }) {
    final trimmed = prompt.trim();
    return _fs.doc(FirestoreCollections.roleplay, id).update({
      'title': title,
      'category': category,
      'difficulty': difficulty,
      'personality': personality,
      'prompt': trimmed,
      'gptPrompt': trimmed,
      'practiceData': practiceData,
      'aiProvider': RoleplayConfigService.openAiProvider,
    });
  }

  Future<void> createSimulation({
    required String title,
    required String category,
    required String prompt,
    required List<Map<String, String>> practiceData,
    required String difficulty,
    required String personality,
  }) {
    final trimmed = prompt.trim();
    return _fs.collection(FirestoreCollections.roleplay).add({
      'title': title,
      'category': category,
      'difficulty': difficulty,
      'personality': personality,
      'prompt': trimmed,
      'gptPrompt': trimmed,
      'practiceData': practiceData,
      'aiProvider': RoleplayConfigService.openAiProvider,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteSimulation(String id) {
    return _fs.doc(FirestoreCollections.roleplay, id).delete();
  }

  Future<void> updatePromptField(String id, String field, String value) {
    return _fs.doc(FirestoreCollections.roleplay, id).update({
      field: value,
    });
  }
}
