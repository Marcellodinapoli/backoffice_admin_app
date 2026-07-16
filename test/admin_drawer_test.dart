import 'package:backoffice_admin_app/services/admin_menu_badge_notifier.dart';
import 'package:backoffice_admin_app/shell/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('drawer keeps stable project destination ids', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: AdminDrawer(
            selectedId: 'creditcore.dashboard',
            badges: const AdminMenuBadges(),
            onSelect: (id) => selected = id,
          ),
        ),
      ),
    );

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('CreditCore'), findsOneWidget);
    expect(find.text('Outfit'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Outfit'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Outfit'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Prompt AI'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Prompt AI'));
    await tester.pumpAndSettle();

    expect(selected, 'outfit.prompts');
    expect(AdminDrawer.creditCoreItems.length, 20);
    expect(AdminDrawer.outfitItems.map((item) => item.$1), [
      'outfit.users',
      'outfit.privacy',
      'outfit.coupons',
      'outfit.plans',
      'outfit.prompts',
    ]);
  });
}
