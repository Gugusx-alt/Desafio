import 'package:flutter/material.dart';
import 'package:feedbacks/pallet.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/models/task.dart';
import 'package:feedbacks/services/refresh_service.dart';
import 'package:feedbacks/widgets/task_detail_screen.dart';
import 'dart:async';

class TasksDashboard extends StatefulWidget {
  const TasksDashboard({super.key});

  @override
  State<TasksDashboard> createState() => _TasksDashboardState();
}

class _TasksDashboardState extends State<TasksDashboard> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _categoryFilter = 'todas';

  late StreamSubscription _refreshSubscription;

  static const _columns = [
    _ColDef('aberta', 'Pendente', statusOpen, Icons.circle_outlined),
    _ColDef('em_andamento', 'Em andamento', statusProgress, Icons.autorenew_rounded),
    _ColDef('concluida', 'Concluída', statusDone, Icons.check_circle_rounded),
    _ColDef('cancelada', 'Cancelada', statusCancelled, Icons.cancel_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _refreshSubscription =
        RefreshService().refreshStream.listen((_) => _loadTasks());
  }

  @override
  void dispose() {
    _refreshSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await ApiService.getAllTasks();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          final data = result['data']['tasks'] as List;
          _tasks = data.map((j) => Task.fromJson(j)).toList();
        } else {
          _errorMessage = result['error'] ?? 'Erro ao carregar tarefas';
        }
      });
    }
  }

  List<Task> _tasksForColumn(String status) {
    return _tasks.where((t) {
      if (t.status != status) return false;
      if (_categoryFilter != 'todas' && t.category != _categoryFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final role = ApiService.currentUserRole ?? '-';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Tarefas'),
        backgroundColor: surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: textSecondary,
            onPressed: _loadTasks,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _CategoryFilter(
            selected: _categoryFilter,
            onChanged: (v) => setState(() => _categoryFilter = v),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: statusCancelled)))
              : RefreshIndicator(
                  onRefresh: _loadTasks,
                  color: primaryColor,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _columns.map((col) {
                            return _KanbanColumn(
                              col: col,
                              tasks: _tasksForColumn(col.status),
                              height: constraints.maxHeight - 32,
                              userRole: role,
                              onOpen: (task) => _openTask(task),
                              onStatusChange: role != 'cliente'
                                  ? (task) => _showStatusDialog(task)
                                  : null,
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _openTask(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
  }

  void _showStatusDialog(Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderColor),
        ),
        title: const Text('Alterar status',
            style: TextStyle(color: textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _columns.map((col) {
            final isCurrent = task.status == col.status;
            return ListTile(
              dense: true,
              leading: Icon(col.icon, color: col.color, size: 18),
              title: Text(col.label,
                  style: TextStyle(
                      color: isCurrent ? col.color : textPrimary,
                      fontSize: 14,
                      fontWeight: isCurrent
                          ? FontWeight.w600
                          : FontWeight.normal)),
              trailing: isCurrent
                  ? Icon(Icons.check_rounded, color: col.color, size: 16)
                  : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMd)),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await ApiService.updateTaskStatus(
                    taskId: task.id, status: col.status);
                if (res['success'] == true) {
                  RefreshService().refreshDashboard();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Status: ${col.label}'),
                      backgroundColor: col.color,
                    ));
                  }
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Definição de coluna ──────────────────────────────────────────────────────
class _ColDef {
  final String status;
  final String label;
  final Color color;
  final IconData icon;
  const _ColDef(this.status, this.label, this.color, this.icon);
}

// ─── Filtro de categoria ──────────────────────────────────────────────────────
class _CategoryFilter extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _CategoryFilter({required this.selected, required this.onChanged});

  static const _options = [
    ('todas', 'Todas', textSecondary),
    ('bug', 'Bug', categoryBug),
    ('ajuste', 'Ajuste', categoryAdjust),
    ('melhoria', 'Melhoria', categoryImprove),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (val, label, color) = _options[i];
          final sel = selected == val;
          return GestureDetector(
            onTap: () => onChanged(val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? color : borderColor, width: 1),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: sel ? color : textMuted,
                  fontSize: 12,
                  fontWeight:
                      sel ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Coluna Kanban ────────────────────────────────────────────────────────────
class _KanbanColumn extends StatelessWidget {
  final _ColDef col;
  final List<Task> tasks;
  final double height;
  final String userRole;
  final void Function(Task) onOpen;
  final void Function(Task)? onStatusChange;

  const _KanbanColumn({
    required this.col,
    required this.tasks,
    required this.height,
    required this.userRole,
    required this.onOpen,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      height: height,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: col.color.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(radiusLg)),
              border: Border(
                  bottom: BorderSide(
                      color: col.color.withOpacity(0.18))),
            ),
            child: Row(
              children: [
                Icon(col.icon, color: col.color, size: 15),
                const SizedBox(width: 7),
                Text(col.label,
                    style: TextStyle(
                        color: col.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: col.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${tasks.length}',
                      style: TextStyle(
                          color: col.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          // Cards
          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded,
                            color: textMuted, size: 28),
                        SizedBox(height: 8),
                        Text('Sem tarefas',
                            style: TextStyle(
                                color: textMuted, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => _KanbanCard(
                      task: tasks[i],
                      onTap: () => onOpen(tasks[i]),
                      onStatusChange: onStatusChange != null
                          ? () => onStatusChange!(tasks[i])
                          : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Kanban ──────────────────────────────────────────────────────────────
class _KanbanCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback? onStatusChange;

  const _KanbanCard({
    required this.task,
    required this.onTap,
    this.onStatusChange,
  });

  @override
  State<_KanbanCard> createState() => _KanbanCardState();
}

class _KanbanCardState extends State<_KanbanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovered ? surfaceElevated : backgroundColor,
            borderRadius: BorderRadius.circular(radiusMd),
            border: Border.all(
              color: _hovered
                  ? t.categoryColor.withOpacity(0.5)
                  : borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título + botão de status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    margin: const EdgeInsets.only(top: 2, right: 8),
                    decoration: BoxDecoration(
                      color: t.categoryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          height: 1.35),
                    ),
                  ),
                  if (widget.onStatusChange != null)
                    GestureDetector(
                      onTap: widget.onStatusChange,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.more_horiz_rounded,
                            size: 16, color: textMuted),
                      ),
                    ),
                ],
              ),
              // Descrição (opcional)
              if (t.description != null &&
                  t.description!.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  t.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: textSecondary, fontSize: 11, height: 1.4),
                ),
              ],
              const SizedBox(height: 9),
              // Rodapé: categoria + criador
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.categoryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.categoryIcon,
                            size: 10, color: t.categoryColor),
                        const SizedBox(width: 3),
                        Text(t.categoryText,
                            style: TextStyle(
                                color: t.categoryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (t.createdByName != null)
                    Text(t.createdByName!,
                        style: const TextStyle(
                            color: textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
