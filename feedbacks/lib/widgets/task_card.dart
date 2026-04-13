import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/task_detail_screen.dart';
import '../pallet.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final String userRole;
  final VoidCallback? onTap;
  final VoidCallback? onStatusChange;

  const TaskCard({
    super.key,
    required this.task,
    required this.userRole,
    this.onTap,
    this.onStatusChange,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _hovered = false;

  Color get _accentColor {
    switch (widget.task.status) {
      case 'aberta':       return statusOpen;
      case 'em_andamento': return statusProgress;
      case 'concluida':    return statusDone;
      case 'cancelada':    return statusCancelled;
      default:             return textMuted;
    }
  }

  Color get _catColor {
    switch (widget.task.category) {
      case 'bug':      return categoryBug;
      case 'ajuste':   return categoryAdjust;
      case 'melhoria': return categoryImprove;
      default:         return textMuted;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'aberta':       return 'Aberta';
      case 'em_andamento': return 'Em andamento';
      case 'concluida':    return 'Concluída';
      case 'cancelada':    return 'Cancelada';
      default:             return status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7)    return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0)    return '${diff.inDays}d atrás';
    if (diff.inHours > 0)   return '${diff.inHours}h atrás';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min';
    return 'agora';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: _hovered ? surfaceElevated : surfaceColor,
          borderRadius: BorderRadius.circular(radiusL),
          border: Border.all(
            color: _hovered ? _accentColor.withOpacity(0.35) : borderColor,
          ),
          boxShadow: _hovered ? shadowCard : [],
        ),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(task: widget.task),
            ),
          ),
          borderRadius: BorderRadius.circular(radiusL),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Linha 1: indicador + título + status ──────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra lateral colorida por categoria
                    Container(
                      width: 3,
                      height: 36,
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      decoration: BoxDecoration(
                        color: _catColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    Expanded(
                      child: Text(
                        widget.task.title,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Pill de status
                    _StatusPill(
                      label: _getStatusText(widget.task.status),
                      color: _accentColor,
                    ),
                  ],
                ),

                // ── Descrição ─────────────────────────────────────────────
                if (widget.task.description != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      widget.task.description!,
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1, color: borderColor),
                const SizedBox(height: 10),

                // ── Rodapé ────────────────────────────────────────────────
                Row(
                  children: [
                    _MetaChip(
                      icon: widget.task.categoryIcon,
                      label: widget.task.categoryText,
                      color: _catColor,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.person_outline, size: 12, color: textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        widget.task.createdByName ?? '#${widget.task.createdBy}',
                        style: const TextStyle(color: textMuted, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatDate(widget.task.createdAt),
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 10,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),

                // ── Botão alterar status (admin / dev) ────────────────────
                if (widget.userRole != 'cliente' && widget.onStatusChange != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: widget.onStatusChange,
                      icon: Icon(Icons.swap_horiz_rounded, size: 14, color: _accentColor),
                      label: Text(
                        'Alterar status',
                        style: TextStyle(
                          fontSize: 12,
                          color: _accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(radiusS),
                          side: BorderSide(color: _accentColor.withOpacity(0.3)),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-componentes ──────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}