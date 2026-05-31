import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Verifica disponibilità biometria
  Future<bool> isBiometricAvailable() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  /// Autenticazione con impronta digitale
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason:
        "Autenticazione richiesta per accedere al BackOffice",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
