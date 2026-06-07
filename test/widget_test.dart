import 'package:backoffice_admin_app/core/theme/app_colors.dart';
import 'package:backoffice_admin_app/features/dashboard/widgets/dashboard_detail_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DashboardDetailCard shows total and details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardDetailCard(
            title: 'Utenti',
            value: '10',
            accentColor: AppColors.primary,
            details: const [
              DashboardDetailItem('Attivi', 8, AppColors.success),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Utenti'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Attivi'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });
}
