import 'package:flutter/material.dart';

import '../auth/admin_login_page.dart';
import '../core/theme/app_colors.dart';
import '../services/auth_service.dart';
import '../shared/widgets/gradient_header.dart';
import '../shell/admin_drawer.dart';
import '../shell/admin_shell.dart';

class ProjectSelectionPage extends StatelessWidget {
  final ValueChanged<String>? onProjectSelected;

  const ProjectSelectionPage({super.key, this.onProjectSelected});

  void _selectProject(BuildContext context, String firstPageId) {
    final callback = onProjectSelected;
    if (callback != null) {
      callback(firstPageId);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AdminShell(initialSelectedId: firstPageId),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientHeader(
        title: 'BackOffice Admin',
        subtitle: 'Seleziona il progetto',
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalLayout = constraints.maxWidth >= 720;
            final cards = [
              _ProjectCard(
                key: const Key('project.creditcore'),
                title: 'CreditCore',
                description: 'Gestisci utenti, aziende, corsi e servizi CreditCore.',
                icon: Icons.account_balance_outlined,
                onTap: () => _selectProject(
                  context,
                  AdminDrawer.firstCreditCoreId,
                ),
              ),
              _ProjectCard(
                key: const Key('project.outfit'),
                title: 'Outfit',
                description: 'Gestisci utenti, privacy, piani e contenuti Outfit.',
                icon: Icons.checkroom_outlined,
                onTap: () => _selectProject(
                  context,
                  AdminDrawer.firstOutfitId,
                ),
              ),
            ];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Quale progetto vuoi amministrare?',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Potrai passare all’altro progetto dal menu laterale.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (horizontalLayout)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 20),
                            Expanded(child: cards[1]),
                          ],
                        )
                      else
                        Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 16),
                            cards[1],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ProjectCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
