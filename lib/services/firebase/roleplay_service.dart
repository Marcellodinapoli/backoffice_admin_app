import '../../core/constants/firestore_collections.dart';
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
    required String gptPrompt,
    required List<Map<String, String>> practiceData,
    required String aiProvider,
  }) {
    return _fs.doc(FirestoreCollections.roleplay, id).update({
      'title': title,
      'category': category,
      'prompt': prompt,
      'gptPrompt': gptPrompt,
      'practiceData': practiceData,
      'aiProvider': aiProvider,
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
