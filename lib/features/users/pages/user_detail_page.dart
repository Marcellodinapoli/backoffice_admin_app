import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/app_user.dart';
import '../../../services/firebase/users_service.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/status_badge.dart';

class UserDetailPage extends StatelessWidget {
  final String userId;

  const UserDetailPage({super.key, required this.userId});

  String _formatDate(dynamic ts) {
    if (ts == null) return 'N/D';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
    } catch (_) {
      return 'N/D';
    }
  }

  Future<void> _promptReason(
    BuildContext context, {
    required String title,
    required Color color,
    required Future<void> Function(String reason) onConfirm,
  }) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Motivazione'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
    if (confirmed == true && ctrl.text.trim().isNotEmpty) {
      await onConfirm(ctrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Dettaglio utente'),
      ),
      body: StreamBuilder<AppUser?>(
        stream: UsersService.instance.watchUser(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingView();
          }
          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('Utente non trovato'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.accentSoft,
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge.fromStatus(user.status),
                          ],
                        ),
                        const Divider(height: 28),
                        _infoRow('Tipo', user.type),
                        _infoRow('Ruolo', user.workRoleLabel),
                        _infoRow('Registrato', _formatDate(user.createdAt)),
                        _infoRow('Ultimo accesso', _formatDate(user.lastLoginAt)),
                        if (user.blockedReason != null)
                          _infoRow('Motivo blocco', user.blockedReason!),
                        if (user.standbyReason != null)
                          _infoRow('Motivo standby', user.standbyReason!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Azioni amministratore',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _actionChip(
                      label: 'Blocca',
                      icon: Icons.block,
                      color: AppColors.error,
                      onTap: () => _promptReason(
                        context,
                        title: 'Blocca utente',
                        color: AppColors.error,
                        onConfirm: (r) =>
                            UsersService.instance.blockUser(userId, r),
                      ),
                    ),
                    _actionChip(
                      label: 'Standby',
                      icon: Icons.pause_circle_outline,
                      color: AppColors.warning,
                      onTap: () => _promptReason(
                        context,
                        title: 'Metti in standby',
                        color: AppColors.warning,
                        onConfirm: (r) =>
                            UsersService.instance.standbyUser(userId, r),
                      ),
                    ),
                    if (user.status != 'active')
                      _actionChip(
                        label: 'Attiva',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                        onTap: () =>
                            UsersService.instance.activateUser(userId),
                      ),
                    _actionChip(
                      label: 'Cambia tipo (${user.type == 'work' ? 'public' : 'work'})',
                      icon: Icons.swap_horiz,
                      color: AppColors.primary,
                      onTap: () =>
                          UsersService.instance.toggleType(userId, user.type),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _actionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }
}
