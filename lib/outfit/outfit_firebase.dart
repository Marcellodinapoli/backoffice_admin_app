import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class OutfitFirebase {
  static const appName = 'outfit';
  static const projectId = 'outfit-ai-d0363';

  static const _apiKey = String.fromEnvironment('OUTFIT_FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('OUTFIT_FIREBASE_APP_ID');
  static const _messagingSenderId =
      String.fromEnvironment('OUTFIT_FIREBASE_MESSAGING_SENDER_ID');

  static final ValueNotifier<String?> unavailableReason = ValueNotifier(null);
  static FirebaseApp? _app;
  static String? _authorizedUid;

  static bool get isConfigured =>
      _apiKey.isNotEmpty && _appId.isNotEmpty && _messagingSenderId.isNotEmpty;
  static bool get isAvailable =>
      _app != null &&
      _authorizedUid != null &&
      auth?.currentUser?.uid == _authorizedUid;
  static String? get authorizedUid => isAvailable ? _authorizedUid : null;
  static FirebaseAuth? get auth =>
      _app == null ? null : FirebaseAuth.instanceFor(app: _app!);
  static FirebaseFirestore? get firestore =>
      _app == null ? null : FirebaseFirestore.instanceFor(app: _app!);

  static Future<void> initialize() async {
    if (!isConfigured) {
      unavailableReason.value =
          'Configurazione Firebase Outfit incompleta nel sibling outfit-ai.';
      return;
    }
    try {
      for (final app in Firebase.apps) {
        if (app.name == appName) {
          _app = app;
          break;
        }
      }
      _app ??= await Firebase.initializeApp(
        name: appName,
        options: const FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _messagingSenderId,
          projectId: projectId,
          authDomain: '$projectId.firebaseapp.com',
          storageBucket: '$projectId.firebasestorage.app',
        ),
      );
      unavailableReason.value = null;
    } catch (error) {
      unavailableReason.value = 'Firebase Outfit non disponibile: $error';
    }
  }

  static Future<bool> signIn(String email, String password) async {
    _authorizedUid = null;
    final instance = auth;
    if (instance == null) {
      unavailableReason.value = 'Firebase Outfit non configurato.';
      return false;
    }
    await _clearSession(instance);
    try {
      final credential = await instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final token = await credential.user?.getIdTokenResult(true);
      if (token?.claims?['admin'] != true) {
        await _clearSession(instance);
        unavailableReason.value =
            'Account privo del claim admin sul progetto Outfit.';
        return false;
      }
      _authorizedUid = credential.user!.uid;
      unavailableReason.value = null;
      return true;
    } catch (error) {
      await _clearSession(instance);
      unavailableReason.value = 'Accesso Outfit non disponibile: $error';
      return false;
    }
  }

  static Future<void> signOut() async {
    _authorizedUid = null;
    final instance = auth;
    if (instance != null) await _clearSession(instance);
    unavailableReason.value = isConfigured
        ? 'Sessione amministrativa Outfit non attiva.'
        : 'Configurazione Firebase Outfit incompleta.';
  }

  static Future<void> _clearSession(FirebaseAuth instance) async {
    _authorizedUid = null;
    try {
      await instance.signOut();
    } catch (_) {
      // CreditCore deve restare utilizzabile anche se il secondario non risponde.
    }
  }
}
