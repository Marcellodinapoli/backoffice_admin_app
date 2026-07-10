import 'package:credit_calc_core/credit_calc_core.dart';
import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';

/// Monitoraggio warm-up telefonata e contestazioni (BackOffice admin).
class WarmupMonitoringPage extends StatelessWidget {
  const WarmupMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return WarmupMonitoringAdminBody(
      verifyAdmin: ({forceRefresh = false}) => authService.isAdmin(),
    );
  }
}
