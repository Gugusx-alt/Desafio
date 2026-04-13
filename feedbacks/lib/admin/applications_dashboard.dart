import 'package:flutter/material.dart';
import 'package:feedbacks/pallet.dart';
import 'package:feedbacks/services/application_service.dart';
import 'package:feedbacks/services/application_management_service.dart';
import 'package:feedbacks/models/application.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/admin/create_application_screen.dart';
import 'package:feedbacks/admin/users_management_screen.dart';
import 'package:feedbacks/admin/all_applications_screen.dart';
import 'package:feedbacks/admin/edit_application_screen.dart';
import 'package:feedbacks/services/refresh_service.dart';
import 'package:feedbacks/login_screen.dart';
import 'dart:async';

class ApplicationsDashboard extends StatefulWidget {
  const ApplicationsDashboard({super.key});

  @override
  State<ApplicationsDashboard> createState() =>
      _ApplicationsDashboardState();
}

class _ApplicationsDashboardState extends State<ApplicationsDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  late StreamSubscription _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedIndex = _tabController.index);
      }
    });
    _refreshSubscription = RefreshService().refreshStream.listen((_) {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshSubscription.cancel();
    super.dispose();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderColor),
        ),
        title: const Text('Sair da conta',
            style: TextStyle(color: textPrimary)),
        content: const Text('Tem certeza que deseja sair?',
            style: TextStyle(color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ApiService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: statusCancelled),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Text(
          _selectedIndex == 0
              ? 'Minhas Aplicações'
              : _selectedIndex == 1
                  ? 'Todas as Aplicações'
                  : 'Usuários',
          style: const TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.add_rounded, color: primaryColor),
              tooltip: 'Nova aplicação',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreateApplicationScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            color: textSecondary,
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          indicatorWeight: 2,
          labelColor: primaryColor,
          unselectedLabelColor: textMuted,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.apps_rounded, size: 18), text: 'Minhas Apps'),
            Tab(icon: Icon(Icons.grid_view_rounded, size: 18), text: 'Todas Apps'),
            Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'Usuários'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MyApplicationsBody(),
          AllApplicationsScreen(),
          UsersManagementScreen(),
        ],
      ),
    );
  }
}

// ─── Aba: Minhas Aplicações ──────────────────────────────────────────────────
class _MyApplicationsBody extends StatefulWidget {
  const _MyApplicationsBody();

  @override
  State<_MyApplicationsBody> createState() =>
      _MyApplicationsManagementScreenState();
}

class _MyApplicationsManagementScreenState
    extends State<_MyApplicationsBody> {
  List<Application> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'todos';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final apps = await ApplicationService.getMyAllApplications();
    if (mounted) {
      setState(() {
        _applications = apps;
        _isLoading = false;
      });
    }
  }

  List<Application> get _filtered {
    List<Application> list = _applications;
    if (_statusFilter != 'todos') {
      list = list.where((a) => a.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((a) =>
              a.name.toLowerCase().contains(q) ||
              (a.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return list;
  }

  Future<void> _handleAction(Application app) async {
    final isInactive = app.status == 'inativo';
    final hasTasks = (app.taskCount ?? 0) > 0;

    final String title, content, btnText;
    final Color btnColor;

    if (isInactive) {
      title = 'Reativar aplicação';
      content =
          'Deseja reativar "${app.name}"?\nEla voltará a aceitar tarefas.';
      btnText = 'Reativar';
      btnColor = statusDone;
    } else if (hasTasks) {
      title = 'Inativar aplicação';
      content =
          '${app.name} possui ${app.taskCount} tarefa(s).\nDeseja inativar esta aplicação?';
      btnText = 'Inativar';
      btnColor = statusProgress;
    } else {
      title = 'Excluir aplicação';
      content =
          'Deseja excluir permanentemente "${app.name}"?\nEsta ação não pode ser desfeita.';
      btnText = 'Excluir';
      btnColor = statusCancelled;
    }

    final confirm = await _confirm(title, content, btnText, btnColor);
    if (confirm != true) return;

    setState(() => _isLoading = true);
    final result =
        await ApplicationManagementService.deleteApplication(app.id);

    if (!mounted) return;

    if (result['success']) {
      final msg = result['reativado'] == true
          ? '"${app.name}" reativada'
          : result['softDelete'] == true
              ? '"${app.name}" inativada'
              : '"${app.name}" excluída';
      _snack(msg);
      _loadApplications();
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

  void _edit(Application app) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => EditApplicationScreen(application: app)),
    );
    if (ok == true) _loadApplications();
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
                  hintText: 'Buscar por nome ou descrição...',
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
                  _chip('Todas', 'todos', textSecondary),
                  const SizedBox(width: 8),
                  _chip('Ativas', 'ativo', statusDone),
                  const SizedBox(width: 8),
                  _chip('Inativas', 'inativo', statusCancelled),
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
                      ? _empty()
                      : RefreshIndicator(
                          onRefresh: _loadApplications,
                          color: primaryColor,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) =>
                                _AppCard(
                              app: _filtered[i],
                              onEdit: () => _edit(_filtered[i]),
                              onAction: () =>
                                  _handleAction(_filtered[i]),
                            ),
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
        _loadApplications();
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
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.apps_rounded, color: textMuted, size: 40),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty
                ? 'Nenhuma aplicação cadastrada'
                : 'Nenhum resultado encontrado',
            style: const TextStyle(color: textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Card de aplicação ────────────────────────────────────────────────────────
class _AppCard extends StatelessWidget {
  final Application app;
  final VoidCallback onEdit;
  final VoidCallback onAction;

  const _AppCard(
      {required this.app,
      required this.onEdit,
      required this.onAction});

  @override
  Widget build(BuildContext context) {
    final isInactive = app.status == 'inativo';
    final hasTasks = (app.taskCount ?? 0) > 0;
    final statusColor = isInactive ? statusCancelled : statusDone;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isInactive
                  ? textMuted.withOpacity(0.1)
                  : primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(radiusS),
            ),
            child: Icon(
              Icons.apps_rounded,
              color: isInactive ? textMuted : primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  style: TextStyle(
                    color: isInactive ? textMuted : textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    decoration: isInactive
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (app.description != null &&
                    app.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    app.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: textSecondary, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Badge(
                        label: isInactive ? 'Inativa' : 'Ativa',
                        color: statusColor),
                    const SizedBox(width: 6),
                    _Badge(
                        label:
                            '${app.taskCount ?? 0} tarefas',
                        color: textMuted,
                        icon: Icons.assignment_rounded),
                  ],
                ),
              ],
            ),
          ),
          // Ações
          Row(
            children: [
              _ActionBtn(
                icon: Icons.edit_rounded,
                color: secondaryColor,
                tooltip: 'Editar',
                onTap: onEdit,
              ),
              const SizedBox(width: 4),
              _ActionBtn(
                icon: isInactive
                    ? Icons.restore_rounded
                    : (hasTasks
                        ? Icons.block_rounded
                        : Icons.delete_outline_rounded),
                color: isInactive
                    ? statusDone
                    : (hasTasks
                        ? statusProgress
                        : statusCancelled),
                tooltip: isInactive
                    ? 'Reativar'
                    : (hasTasks ? 'Inativar' : 'Excluir'),
                onTap: onAction,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
