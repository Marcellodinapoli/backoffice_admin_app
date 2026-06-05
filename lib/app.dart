import 'package:flutter/material.dart';

import 'auth/admin_login_page.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'shell/admin_shell.dart';

class BackOfficeAdminApp extends StatelessWidget {
  const BackOfficeAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BackOffice Admin',
      theme: buildAppTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const AdminLoginPage(),
        AppRoutes.shell: (_) => const AdminShell(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.shell) {
          return MaterialPageRoute(builder: (_) => const AdminShell());
        }
        return null;
      },
    );
  }
}
