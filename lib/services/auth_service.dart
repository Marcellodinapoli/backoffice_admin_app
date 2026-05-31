import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Login con email e password
  Future<User?> login(String email, String password) async {
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
        return user;
      } else {
        await _auth.signOut();
        throw Exception("Utente non autorizzato (non admin)");
      }
    } on FirebaseAuthException catch (e) {
      throw Exception("Errore login: ${e.code}");
    }
  }

  /// Logout
  Future<void> logout() async {
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
