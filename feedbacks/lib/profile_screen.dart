import 'package:flutter/material.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/login_screen.dart';
import 'package:feedbacks/pallet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ApiService.getCurrentUser();
    final role = user?['role'] as String? ?? '-';

    final roleLabel = switch (role) {
      'admin'         => 'Administrador',
      'desenvolvedor' => 'Desenvolvedor',
      'cliente'       => 'Cliente',
      _               => role,
    };

    final roleColor = switch (role) {
      'admin'         => const Color(0xFFB083FF),
      'desenvolvedor' => statusDone,
      'cliente'       => statusOpen,
      _               => textMuted,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(radiusL),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(radiusM),
                      border: Border.all(color: roleColor.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.person_outline, color: roleColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conta conectada',
                          style: TextStyle(
                            color: textMuted, fontSize: 11, letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID #${user?['id'] ?? '-'}',
                          style: const TextStyle(
                            color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: roleColor.withOpacity(0.25)),
                          ),
                          child: Text(
                            roleLabel,
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Detalhes ──────────────────────────────────────────────────
            _InfoRow(label: 'ID do usuário',   value: '#${user?['id'] ?? '-'}'),
            _InfoRow(label: 'Nível de acesso', value: roleLabel),

            const SizedBox(height: 28),

            // ── Zona de perigo ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusCancelled.withOpacity(0.04),
                borderRadius: BorderRadius.circular(radiusL),
                border: Border.all(color: statusCancelled.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.warning_amber_outlined, size: 14, color: statusCancelled),
                    SizedBox(width: 6),
                    Text(
                      'Zona de perigo',
                      style: TextStyle(
                        color: statusCancelled,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLogout(context),
                      icon: const Icon(Icons.logout, size: 15),
                      label: const Text('Sair da conta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: statusCancelled,
                        side: BorderSide(color: statusCancelled.withOpacity(0.5)),
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radiusM),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você precisará fazer login novamente para acessar o sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ApiService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: statusCancelled),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radiusM),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: textSecondary, fontSize: 12),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}