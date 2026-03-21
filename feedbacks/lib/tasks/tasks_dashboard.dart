import 'package:flutter/material.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/models/task.dart';
import 'package:feedbacks/widgets/task_card.dart';
import 'package:feedbacks/services/refresh_service.dart';
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
  String _statusFilter = 'todos'; // 'todos', 'aberta', 'em_andamento', 'concluida', 'cancelada'
  String _categoryFilter = 'todas'; // 'todas', 'bug', 'ajuste', 'melhoria'
  
  late StreamSubscription _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    
    _refreshSubscription = RefreshService().refreshStream.listen((_) {
      _loadTasks();
    });
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
          final tasksData = result['data']['tasks'] as List;
          _tasks = tasksData.map((json) => Task.fromJson(json)).toList();
        } else {
          _errorMessage = result['error'] ?? 'Erro ao carregar tarefas';
        }
      });
    }
  }

  List<Task> get _filteredTasks {
    List<Task> filtered = _tasks;
    
    // Filtro por status
    if (_statusFilter != 'todos') {
      filtered = filtered.where((task) => task.status == _statusFilter).toList();
    }
    
    // Filtro por categoria
    if (_categoryFilter != 'todas') {
      filtered = filtered.where((task) => task.category == _categoryFilter).toList();
    }
    
    return filtered;
  }

  Map<String, List<Task>> get _groupedTasks {
    final Map<String, List<Task>> grouped = {
      'aberta': [],
      'em_andamento': [],
      'concluida': [],
      'cancelada': [],
    };
    
    for (var task in _filteredTasks) {
      if (grouped.containsKey(task.status)) {
        grouped[task.status]!.add(task);
      }
    }
    
    return grouped;
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'aberta': return '📋 Pendentes';
      case 'em_andamento': return '⚙️ Em Andamento';
      case 'concluida': return '✅ Concluídas';
      case 'cancelada': return '❌ Canceladas';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'aberta': return Colors.blue;
      case 'em_andamento': return Colors.orange;
      case 'concluida': return Colors.green;
      case 'cancelada': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ApiService.currentUserRole ?? '-';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefas'),
        backgroundColor: Colors.deepPurple,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Filtro por status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusFilterChip('Todas', 'todos', Colors.grey),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip('Pendentes', 'aberta', Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip('Em Andamento', 'em_andamento', Colors.orange),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip('Concluídas', 'concluida', Colors.green),
                    const SizedBox(width: 8),
                    _buildStatusFilterChip('Canceladas', 'cancelada', Colors.red),
                  ],
                ),
                const SizedBox(height: 8),
                // Filtro por categoria
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCategoryFilterChip('Todas', 'todas', Colors.grey),
                    const SizedBox(width: 8),
                    _buildCategoryFilterChip('🐛 Bug', 'bug', Colors.red),
                    const SizedBox(width: 8),
                    _buildCategoryFilterChip('🔧 Ajuste', 'ajuste', Colors.orange),
                    const SizedBox(width: 8),
                    _buildCategoryFilterChip('📈 Melhoria', 'melhoria', Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _filteredTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('Nenhuma tarefa encontrada'),
                          if (role == 'cliente')
                            ElevatedButton(
                              onPressed: () {
                                // Navegar para criar tarefa
                              },
                              child: const Text('Criar primeira tarefa'),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTasks,
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: _groupedTasks.entries.map((entry) {
                          if (entry.value.isEmpty) return const SizedBox.shrink();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header da seção
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                margin: const EdgeInsets.only(top: 8, bottom: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(entry.key).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(entry.key),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getStatusTitle(entry.key),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(entry.key),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(entry.key).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${entry.value.length}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(entry.key),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Lista de tarefas
                              ...entry.value.map((task) => TaskCard(
                                task: task,
                                userRole: role,
                                onTap: () => _showTaskDetails(task),
                                onStatusChange: role != 'cliente'
                                    ? () => _showStatusDialog(task)
                                    : null,
                              )),
                              const SizedBox(height: 8),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
    );
  }

  Widget _buildStatusFilterChip(String label, String value, Color color) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _statusFilter = value);
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey.shade300,
        width: 1,
      ),
    );
  }

  Widget _buildCategoryFilterChip(String label, String value, Color color) {
    final isSelected = _categoryFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _categoryFilter = value);
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey.shade300,
        width: 1,
      ),
    );
  }

  void _showTaskDetails(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: task.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(task.statusIcon, color: task.statusColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Status: ${_getStatusTitle(task.status)}', style: TextStyle(color: task.statusColor)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(task.categoryIcon, size: 14, color: task.categoryColor),
                                const SizedBox(width: 4),
                                Text(task.categoryText, style: TextStyle(color: task.categoryColor)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Descrição', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(task.description ?? 'Sem descrição'),
                  ),
                  const SizedBox(height: 24),
                  const Text('Informações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildInfoRow('ID', task.id.toString()),
                  _buildInfoRow('Aplicação', 'App #${task.applicationId}'),
                  _buildInfoRow('Criado por', 'Usuário #${task.createdBy}'),
                  _buildInfoRow('Criado em', _formatDate(task.createdAt)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStatusDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(task, 'aberta', 'Pendente', Colors.blue),
            _buildStatusOption(task, 'em_andamento', 'Em Andamento', Colors.orange),
            _buildStatusOption(task, 'concluida', 'Concluída', Colors.green),
            _buildStatusOption(task, 'cancelada', 'Cancelada', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(Task task, String status, String label, Color color) {
    return ListTile(
      leading: Icon(status == task.status ? Icons.radio_button_checked : Icons.radio_button_off, color: color),
      title: Text(label),
      onTap: () async {
        Navigator.pop(context);
        final result = await ApiService.updateTaskStatus(taskId: task.id, status: status);
        if (result['success'] == true) {
          RefreshService().refreshDashboard();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status alterado para $label'), backgroundColor: Colors.green),
          );
        }
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get role => ApiService.currentUserRole ?? '-';
}