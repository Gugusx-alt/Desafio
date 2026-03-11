import 'package:flutter/material.dart';
import 'package:feedbacks/create_task_screen.dart';
import 'package:feedbacks/admin/applications_dashboard.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/models/task.dart';
import 'package:feedbacks/widgets/task_card.dart';
import 'package:feedbacks/profile_screen.dart';
import 'package:feedbacks/services/refresh_service.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  
  // Para tasks (cliente/dev)
  List<Task> _tasks = [];
  
  bool _isLoading = true;
  String? _errorMessage;

  late StreamSubscription _refreshSubscription;

  @override
  void initState() {
    super.initState();
    
    final role = ApiService.currentUserRole;
    
    // Se não for admin, carrega tarefas
    if (role != 'admin') {
      _loadTasks();
    }
    
    _refreshSubscription = RefreshService().refreshStream.listen((_) {
      print('🔄 [Dashboard] Stream recebido! Recarregando...');
      if (ApiService.currentUserRole != 'admin') {
        _loadTasks();
      }
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

    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final role = ApiService.currentUserRole ?? '-';
    
    // ADMIN: Mostra o dashboard de aplicações diretamente
    if (role == 'admin') {
      return const ApplicationsDashboard();
    }
    
    // CLIENTE/DEV: Mostra o dashboard normal com NavigationRail
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.selected,
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              
              if (role == 'cliente')
                const NavigationRailDestination(
                  icon: Icon(Icons.add_task),
                  selectedIcon: Icon(Icons.add_task),
                  label: Text('Nova Tarefa'),
                ),
              
              const NavigationRailDestination(
                icon: Icon(Icons.person),
                selectedIcon: Icon(Icons.person),
                label: Text('Perfil'),
              ),
            ].whereType<NavigationRailDestination>().toList(),
          ),
          
          Expanded(
            child: _buildContent(_selectedIndex, role),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(int index, String role) {
    switch (index) {
      case 0: // Dashboard (mostra tarefas)
        return _buildTasksScreen();
      
      case 1: // Nova Tarefa (só existe para cliente)
        if (role == 'cliente') {
          return const CreateTaskScreen();
        }
        return const ProfileScreen();
      
      case 2: // Perfil
        return const ProfileScreen();
      
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTasksScreen() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTasks,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              role == 'cliente' 
                  ? 'Nenhuma tarefa criada' 
                  : 'Nenhuma tarefa encontrada',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            if (ApiService.currentUserRole == 'cliente') ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _selectedIndex = 1);
                },
                child: const Text('Criar primeira tarefa'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return TaskCard(
            task: task,
            userRole: ApiService.currentUserRole ?? '-',
            onTap: () => _showTaskDetails(task),
            onStatusChange: ApiService.currentUserRole != 'cliente'
                ? () => _showStatusDialog(task)
                : null,
          );
        },
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
                        child: Icon(
                          task.statusIcon,
                          color: task.statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${_getStatusText(task.status)}',
                              style: TextStyle(
                                color: task.statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Descrição',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      task.description ?? 'Sem descrição',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Informações',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('ID da Tarefa', task.id.toString()),
                  _buildInfoRow('Aplicação', 'App #${task.applicationId}'),
                  _buildInfoRow('Criado por', 'Usuário #${task.createdBy}'),
                  if (task.assignedTo != null)
                    _buildInfoRow('Atribuído para', 'Usuário #${task.assignedTo}'),
                  _buildInfoRow('Criado em', _formatDate(task.createdAt)),
                  if (task.updatedAt != null)
                    _buildInfoRow('Atualizado em', _formatDate(task.updatedAt!)),
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Alterar Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusOption(task, 'aberta'),
              _buildStatusOption(task, 'em_andamento'),
              _buildStatusOption(task, 'concluida'),
              _buildStatusOption(task, 'cancelada'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(Task task, String status) {
    final color = _getStatusColor(status);
    return ListTile(
      leading: Icon(_getStatusIcon(status), color: color),
      title: Text(_getStatusText(status)),
      onTap: () async {
        Navigator.pop(context);
        final result = await ApiService.updateTaskStatus(
          taskId: task.id,
          status: status,
        );
        if (result['success'] == true) {
          RefreshService().refreshDashboard();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status atualizado para ${_getStatusText(status)}'),
              backgroundColor: Colors.green,
            ),
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
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'aberta': return 'Aberta';
      case 'em_andamento': return 'Em Andamento';
      case 'concluida': return 'Concluída';
      case 'cancelada': return 'Cancelada';
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'aberta': return Icons.pending_actions;
      case 'em_andamento': return Icons.play_circle;
      case 'concluida': return Icons.check_circle;
      case 'cancelada': return Icons.cancel;
      default: return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get role => ApiService.currentUserRole ?? '-';
}