import 'package:flutter/material.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/services/application_service.dart';
import 'package:feedbacks/services/refresh_service.dart';
import 'package:feedbacks/pallet.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();

  int?   _selectedApplicationId;
  String _selectedCategory          = 'ajuste';
  bool   _isLoading                 = false;
  bool   _isLoadingApplications     = true;
  List<Map<String, dynamic>> _applications = [];
  String? _errorInfo;

  static const List<_CategoryOption> _categories = [
    _CategoryOption('bug',      '🐛  Bug',      categoryBug,    'Algo que não funciona corretamente'),
    _CategoryOption('ajuste',   '🔧  Ajuste',   categoryAdjust, 'Modificação ou correção pontual'),
    _CategoryOption('melhoria', '📈  Melhoria', categoryImprove,'Nova funcionalidade ou aprimoramento'),
  ];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() { _isLoadingApplications = true; _errorInfo = null; });
    final apps = await ApplicationService.getMyApplications();
    if (!mounted) return;
    setState(() {
      _applications = apps.map((a) => {'id': a.id, 'name': a.name}).toList();
      if (_applications.isNotEmpty) {
        _selectedApplicationId = _applications.first['id'] as int;
      } else {
        _errorInfo = 'Você não está vinculado a nenhuma aplicação.';
      }
      _isLoadingApplications = false;
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) { _snack('Preencha o título da tarefa'); return; }
    if (_selectedApplicationId == null) { _snack('Selecione uma aplicação'); return; }
    if (ApiService.currentUserRole != 'cliente') {
      _snack('Apenas clientes podem criar tarefas');
      return;
    }

    setState(() { _isLoading = true; _errorInfo = null; });

    final result = await ApiService.createTask(
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null : _descriptionController.text.trim(),
      applicationId: _selectedApplicationId!,
      category: _selectedCategory,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      _titleController.clear();
      _descriptionController.clear();
      RefreshService().refreshDashboard();
      _snack('Tarefa criada com sucesso', success: true);
    } else {
      setState(() { _errorInfo = result['error'] ?? 'Erro ao criar tarefa'; });
      _snack(_errorInfo!);
    }
    setState(() => _isLoading = false);
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          success ? Icons.check_circle_outline : Icons.error_outline,
          size: 16,
          color: success ? statusDone : statusCancelled,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova tarefa')),
      body: _isLoadingApplications
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Título ──────────────────────────────────────────────
                    const _SectionLabel('Título *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      enabled: !_isLoading,
                      style: const TextStyle(color: textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Ex: Botão de salvar não responde',
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Descrição ───────────────────────────────────────────
                    const _SectionLabel('Descrição'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      enabled: !_isLoading,
                      style: const TextStyle(color: textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Descreva o contexto, passos para reproduzir, etc.',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Categoria ───────────────────────────────────────────
                    const _SectionLabel('Categoria *'),
                    const SizedBox(height: 8),
                    ..._categories.map((cat) => _CategoryTile(
                      option: cat,
                      selected: _selectedCategory == cat.value,
                      disabled: _isLoading,
                      onTap: () => setState(() => _selectedCategory = cat.value),
                    )),
                    const SizedBox(height: 18),

                    // ── Aplicação ───────────────────────────────────────────
                    const _SectionLabel('Aplicação *'),
                    const SizedBox(height: 6),

                    if (_applications.isEmpty)
                      _EmptyApps(onRetry: _loadApplications)
                    else
                      DropdownButtonFormField<int>(
                        value: _selectedApplicationId,
                        dropdownColor: surfaceElevated,
                        style: const TextStyle(color: textPrimary, fontSize: 13),
                        decoration: const InputDecoration(),
                        items: _applications.map((app) => DropdownMenuItem<int>(
                          value: app['id'] as int,
                          child: Text(app['name'] as String),
                        )).toList(),
                        onChanged: !_isLoading
                            ? (v) => setState(() => _selectedApplicationId = v)
                            : null,
                      ),

                    // ── Bloco de erro ───────────────────────────────────────
                    if (_errorInfo != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusCancelled.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(radiusM),
                          border: Border.all(color: statusCancelled.withOpacity(0.25)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, size: 14, color: statusCancelled),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorInfo!,
                              style: const TextStyle(color: statusCancelled, fontSize: 12),
                            ),
                          ),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ── Submit ──────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _applications.isEmpty) ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 18, width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: backgroundColor,
                                ),
                              )
                            : const Text('Criar tarefa'),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'A tarefa será enviada para análise da equipe',
                        style: TextStyle(color: textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─── Modelo local ─────────────────────────────────────────────────────────────

class _CategoryOption {
  final String value;
  final String label;
  final Color  color;
  final String description;
  const _CategoryOption(this.value, this.label, this.color, this.description);
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _CategoryOption option;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.option,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? option.color.withOpacity(0.08) : surfaceColor,
          borderRadius: BorderRadius.circular(radiusM),
          border: Border.all(
            color: selected ? option.color.withOpacity(0.5) : borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 16, height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? option.color : Colors.transparent,
              border: Border.all(
                color: selected ? option.color : borderColor,
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 10, color: backgroundColor)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: TextStyle(
                    color: selected ? option.color : textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  option.description,
                  style: const TextStyle(color: textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyApps extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyApps({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(radiusM),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, color: textMuted, size: 28),
          const SizedBox(height: 8),
          const Text(
            'Nenhuma aplicação vinculada',
            style: TextStyle(
              color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Fale com o administrador para vincular sua conta.',
            style: TextStyle(color: textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}