import 'package:flutter/material.dart';
import 'package:feedbacks/pallet.dart';
import 'package:feedbacks/services/user_management_service.dart';
import 'package:feedbacks/services/refresh_service.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/admin/edit_user_screen.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() =>
      _UsersManagementScreenState();
}

class _UsersManagementScreenState
    extends State<UsersManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'todos';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final status = _statusFilter == 'todos' ? null : _statusFilter;
    final users =
        await UserManagementService.getAllUsers(status: status);
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _users;
    final q = _searchQuery.toLowerCase();
    return _users
        .where((u) =>
            u['name'].toString().toLowerCase().contains(q) ||
            u['email'].toString().toLowerCase().contains(q))
        .toList();
  }

  Future<void> _handleAction(Map<String, dynamic> user) async {
    if (user['id'] == ApiService.currentUserId) {
      _snack('Você não pode alterar seu próprio usuário', error: true);
      return;
    }

    final isInactive = user['status'] == 'inativo';
    final taskCount = user['task_count'] ?? 0;
    final hasTasks = taskCount > 0;

    final String title, content, btnText;
    final Color btnColor;

    if (isInactive) {
      title = 'Reativar usuário';
      content = 'Deseja reativar "${user['name']}"?';
      btnText = 'Reativar';
      btnColor = statusDone;
    } else if (hasTasks) {
      title = 'Inativar usuário';
      content =
          '${user['name']} possui $taskCount tarefa(s).\nDeseja inativar este usuário?';
      btnText = 'Inativar';
      btnColor = statusProgress;
    } else {
      title = 'Excluir usuário';
      content =
          'Deseja excluir "${user['name']}" permanentemente?';
      btnText = 'Excluir';
      btnColor = statusCancelled;
    }

    final confirm = await _confirm(title, content, btnText, btnColor);
    if (confirm != true) return;

    setState(() => _isLoading = true);
    final result =
        await UserManagementService.deleteUser(user['id']);

    if (!mounted) return;

    if (result['success']) {
      final msg = result['reativado'] == true
          ? 'Usuário reativado'
          : result['softDelete'] == true
              ? 'Usuário inativado'
              : 'Usuário excluído';
      _snack(msg);
      _loadUsers();
      RefreshService().refreshDashboard();
    } else {
      _snack(result['error'] ?? 'Erro', error: true);
      setState(() => _isLoading = false);
    }
  }

  Future<bool?> _confirm(
      String title, String content, String btnText, Color btnColor) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderColor),
        ),
        title: Text(title,
            style: const TextStyle(color: textPrimary, fontSize: 16)),
        content: Text(content,
            style: const TextStyle(color: textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: btnColor),
            child: Text(btnText),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? statusCancelled : statusDone,
    ));
  }

  void _edit(Map<String, dynamic> user) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditUserScreen(user: user)),
    );
    if (ok == true) _loadUsers();
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return secondaryColor;
      case 'desenvolvedor':
        return accentColor;
      default:
        return primaryColor;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'desenvolvedor':
        return 'Dev';
      default:
        return 'Cliente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de busca + filtros
        Container(
          color: surfaceColor,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por nome ou e-mail...',
                  hintStyle:
                      const TextStyle(color: textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: textMuted, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radiusMd),
                    borderSide:
                        const BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radiusMd),
                    borderSide:
                        const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radiusMd),
                    borderSide: const BorderSide(
                        color: primaryColor, width: 1.5),
                  ),
                  filled: true,
                  fillColor: surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
                style: const TextStyle(
                    color: textPrimary, fontSize: 13),
                onChanged: (v) =>
                    setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _chip('Todos', 'todos', textSecondary),
                  const SizedBox(width: 8),
                  _chip('Ativos', 'ativo', statusDone),
                  const SizedBox(width: 8),
                  _chip('Inativos', 'inativo', statusCancelled),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    color: textMuted,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _loadUsers,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: borderColor),
        // Lista
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: primaryColor))
              : _errorMessage != null
                  ? Center(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              color: statusCancelled)))
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline_rounded,
                                  color: textMuted, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Nenhum usuário cadastrado'
                                    : 'Nenhum resultado encontrado',
                                style: const TextStyle(
                                    color: textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          color: primaryColor,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final user = _filtered[i];
                              final isMe =
                                  user['id'] == ApiService.currentUserId;
                              final isInactive =
                                  user['status'] == 'inativo';
                              final taskCount =
                                  user['task_count'] ?? 0;
                              final hasTasks = taskCount > 0;
                              final rColor =
                                  _roleColor(user['role'] as String);

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius:
                                      BorderRadius.circular(radiusMd),
                                  border: Border.all(
                                      color: isMe
                                          ? primaryColor.withOpacity(0.3)
                                          : borderColor),
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: rColor.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        (user['name'] as String)[0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                            color: rColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  user['name'] as String,
                                                  style: TextStyle(
                                                    color: isInactive
                                                        ? textMuted
                                                        : textPrimary,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    fontSize: 14,
                                                    decoration: isInactive
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              if (isMe)
                                                Container(
                                                  margin:
                                                      const EdgeInsets.only(
                                                          left: 6),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: primaryColor
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(4),
                                                  ),
                                                  child: const Text(
                                                    'Você',
                                                    style: TextStyle(
                                                        color: primaryColor,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            user['email'] as String,
                                            style: const TextStyle(
                                                color: textSecondary,
                                                fontSize: 12),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              _RoleBadge(
                                                  label: _roleLabel(
                                                      user['role']
                                                          as String),
                                                  color: rColor),
                                              const SizedBox(width: 6),
                                              _RoleBadge(
                                                label: '$taskCount tarefas',
                                                color: textMuted,
                                                icon: Icons
                                                    .assignment_rounded,
                                              ),
                                              const SizedBox(width: 6),
                                              _RoleBadge(
                                                label: isInactive
                                                    ? 'Inativo'
                                                    : 'Ativo',
                                                color: isInactive
                                                    ? statusCancelled
                                                    : statusDone,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Ações
                                    if (!isMe)
                                      Row(
                                        children: [
                                          _ActionBtn(
                                            icon: Icons.edit_rounded,
                                            color: secondaryColor,
                                            tooltip: 'Editar',
                                            onTap: () => _edit(user),
                                          ),
                                          const SizedBox(width: 4),
                                          _ActionBtn(
                                            icon: isInactive
                                                ? Icons.restore_rounded
                                                : (hasTasks
                                                    ? Icons.block_rounded
                                                    : Icons
                                                        .delete_outline_rounded),
                                            color: isInactive
                                                ? statusDone
                                                : (hasTasks
                                                    ? statusProgress
                                                    : statusCancelled),
                                            tooltip: isInactive
                                                ? 'Reativar'
                                                : (hasTasks
                                                    ? 'Inativar'
                                                    : 'Excluir'),
                                            onTap: () =>
                                                _handleAction(user),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _chip(String label, String value, Color color) {
    final sel = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
        _loadUsers();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? color : borderColor, width: 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? color : textMuted,
                fontSize: 12,
                fontWeight:
                    sel ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _RoleBadge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.color,
      required this.tooltip,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusS),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
