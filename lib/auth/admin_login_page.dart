import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../shell/admin_shell.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();
  final _biometricService = BiometricService();
  final _secureStorage = const FlutterSecureStorage();

  bool _loading = false;
  String? _error;

  Future<void> _loginEmail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text.trim();

      final user = await _authService.login(email, password);

      if (user != null) {
        await _secureStorage.write(key: 'admin_email', value: email);
        await _secureStorage.write(key: 'admin_password', value: password);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminShell()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loginBiometric() async {
    setState(() {
      _error = null;
    });

    final success = await _biometricService.authenticate();
    if (!success) return;

    final email = await _secureStorage.read(key: 'admin_email');
    final password = await _secureStorage.read(key: 'admin_password');

    if (email == null || password == null) {
      setState(() {
        _error = "Effettua prima un login con email.";
      });
      return;
    }

    try {
      final user = await _authService.login(email, password);

      if (user != null) {
        final isAdmin = await _authService.isAdmin();

        if (isAdmin && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminShell()),
          );
        } else {
          setState(() {
            _error = "Utente non admin.";
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xFF1B263B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "BackOffice Admin",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(color: Colors.black),
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(color: Colors.black),
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // BOTTONI AFFIANCATI
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _loginEmail,
                      style: buttonStyle,
                      child: _loading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loginBiometric,
                      style: buttonStyle,
                      child: const Text(
                        "Biometria",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 20),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
