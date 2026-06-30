import 'package:credit_calc_core/credit_calc_core.dart';
import 'package:flutter/material.dart';

import '../../../core/subscription/plan_limits_refresh.dart';
import '../../../services/auth_service.dart';

/// Editor piani FREE / PLUS / ENTERPRISE (sincronizzato con CreditPlanet e CreditCalc).
class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return PublicPlanLimitsAdminBody(
      verifyAdmin: ({forceRefresh = false}) => authService.isAdmin(),
      onPlansSaved: () async {
        PlanLimitsRefresh.bump();
      },
    );
  }
}
