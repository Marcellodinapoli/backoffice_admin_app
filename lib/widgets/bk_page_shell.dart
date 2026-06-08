import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Corpo pagina allineato a CreditCalc / [PageShellBody] di CreditPlanet.
class BkPageShellBody extends StatelessWidget {
  final String? pageTitle;
  final Widget child;
  final bool showPageTitle;

  const BkPageShellBody({
    super.key,
    required this.child,
    this.pageTitle,
    this.showPageTitle = true,
  });

  static bool _isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static EdgeInsets _paddingFor(BuildContext context) {
    if (_isPhone(context)) {
      return const EdgeInsets.fromLTRB(8, 8, 8, 10);
    }
    return const EdgeInsets.fromLTRB(16, 12, 16, 14);
  }

  static double _titleSizeFor(BuildContext context) =>
      _isPhone(context) ? 18.0 : 22.0;

  static double _spacingFor(BuildContext context) =>
      _isPhone(context) ? 12.0 : 20.0;

  @override
  Widget build(BuildContext context) {
    final padding = _paddingFor(context);
    final titleSize = _titleSizeFor(context);
    final spacing = _spacingFor(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isPhone = _isPhone(context);

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showPageTitle &&
                pageTitle != null &&
                pageTitle!.isNotEmpty) ...[
              Text(
                pageTitle!,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: spacing),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final area = Padding(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: child,
                      ),
                    ),
                  );

                  if (isPhone) return area;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 1300,
                        minHeight: constraints.maxHeight,
                      ),
                      child: area,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
