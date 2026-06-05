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
}
