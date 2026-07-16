import 'package:firebase_auth/firebase_auth.dart';

import '../outfit/outfit_firebase.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Login con email e password
  Future<User?> login(String email, String password) async {
    // Ogni tentativo parte senza una sessione Outfit precedente. Il login
    // secondario resta fail-open esclusivamente per CreditCore.
    await OutfitFirebase.signOut();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) return null;

      final tokenResult = await user.getIdTokenResult(true);

      // Verifica claim admin
      if (tokenResult.claims?['admin'] == true) {
        await OutfitFirebase.signIn(email.trim(), password);
        return user;
      } else {
        await _auth.signOut();
        await OutfitFirebase.signOut();
        throw Exception("Utente non autorizzato (non admin)");
      }
    } on FirebaseAuthException catch (e) {
      throw Exception("Errore login: ${e.code}");
    }
  }

  /// Logout
  Future<void> logout() async {
    await OutfitFirebase.signOut();
    await _auth.signOut();
  }

  /// Utente corrente
  User? get currentUser => _auth.currentUser;

  /// Controlla se utente è admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final token = await user.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }
}
