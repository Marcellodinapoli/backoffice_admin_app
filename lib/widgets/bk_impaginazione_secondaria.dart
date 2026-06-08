import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/admin_login_page.dart';
import '../core/theme/app_colors.dart';
import 'bk_page_shell.dart';

/// Impaginazione secondaria BackOffice — stessa struttura di CreditCalc.
class ImpaginazioneSecondariaBk extends StatelessWidget {
  final String pageTitle;
  final Widget body;

  const ImpaginazioneSecondariaBk({
    super.key,
    required this.pageTitle,
    required this.body,
  });

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: const Color(0xFFECEFF1),
        elevation: 1,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Back',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: 'Office',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: BkPageShellBody(
        pageTitle: pageTitle,
        child: body,
      ),
    );
  }
}
