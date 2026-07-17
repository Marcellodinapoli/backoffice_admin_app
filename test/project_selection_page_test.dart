import 'package:backoffice_admin_app/home/project_selection_page.dart';
import 'package:backoffice_admin_app/shell/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('project selection exposes both first destinations', (tester) async {
    String? selectedId;

    await tester.pumpWidget(
      MaterialApp(
        home: ProjectSelectionPage(
          onProjectSelected: (id) => selectedId = id,
        ),
      ),
    );

    expect(find.text('CreditCore'), findsOneWidget);
    expect(find.text('Outfit'), findsOneWidget);

    await tester.tap(find.byKey(const Key('project.creditcore')));
    expect(selectedId, AdminDrawer.firstCreditCoreId);

    await tester.tap(find.byKey(const Key('project.outfit')));
    expect(selectedId, AdminDrawer.firstOutfitId);
  });
}
