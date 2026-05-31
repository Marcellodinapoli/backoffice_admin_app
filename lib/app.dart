import 'package:flutter/material.dart';

import 'auth/admin_login_page.dart';
import 'core/theme.dart';

class BackOfficeAdminApp extends StatelessWidget {
  const BackOfficeAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BackOffice Admin',
      theme: buildAdminTheme(),
      home: const AdminLoginPage(),
    );
  }
}
