import 'package:flutter/material.dart';
import 'package:feedbacks/create_task_screen.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/models/task.dart';
import 'package:feedbacks/widgets/task_card.dart';
import 'package:feedbacks/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Índice da aba selecionada no NavigationRail
  int _selectedIndex = 0;
  
  // Lista de tarefas carregadas da API
  List<Task> _tasks = [];
  
  // Estados de carregamento e erro
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTasks(); // Carrega as tarefas ao iniciar a tela
  }

  /// Carrega todas as tarefas do sistema via ApiService.getAllTasks()
  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Busca TODAS as tarefas (independente do role do usuário)
    final result = await ApiService.getAllTasks();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        // Converte o JSON para objetos Task
        final tasksData = result['data']['tasks'] as List;
        _tasks = tasksData.map((json) => Task.fromJson(json)).toList();
      } else {
        _errorMessage = result['error'] ?? 'Erro ao carregar tarefas';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtém o role do usuário atual (admin, cliente, desenvolvedor)
    final role = ApiService.currentUserRole ?? '-';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Row(
        children: [
          
          // Menu de navegação na lateral esquerda
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.selected,
            destinations: [
              // Aba Dashboard (sempre visível)
              const NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              // Aba Nova Tarefa (visível apenas para clientes)
              if (role == 'cliente')
                const NavigationRailDestination(
                  icon: Icon(Icons.add_task),
                  selectedIcon: Icon(Icons.add_task),
                  label: Text('Nova Tarefa'),
                ),
              // Aba Perfil (sempre visível)
              const NavigationRailDestination(
                icon: Icon(Icons.person),
                selectedIcon: Icon(Icons.person),
                label: Text('Perfil'),
              ),
            ].whereType<NavigationRailDestination>().toList(),
          ),
          
          
          // Área que muda conforme a aba selecionada
          Expanded(
            child: _buildContent(_selectedIndex, role),
          ),
        ],
      ),
    );
  }

  /// Constrói o conteúdo da aba selecionada
  /// 
  /// [index] - Índice da aba selecionada
  /// [role] - Role do usuário atual
  Widget _buildContent(int index, String role) {
    switch (index) {
      case 0: // Aba Dashboard
        return _buildTasksScreen();
      
      case 1: // Aba Nova Tarefa (só existe para cliente)
        if (role == 'cliente') {
          return const CreateTaskScreen();
        }
        return const ProfileScreen(); // Fallback (não deve acontecer)
      
      case 2: // Aba Perfil
        return const ProfileScreen();
      
      default:
        return const SizedBox.shrink();
    }
  }

  /// Constrói a tela de listagem de tarefas (Dashboard)
  /// Gerencia 4 estados diferentes:
  /// 1. Carregando: Mostra CircularProgressIndicator
  /// 2. Erro: Mostra mensagem de erro + botão tentar novamente
  /// 3. Vazio: Mostra mensagem que não há tarefas
  /// 4. Sucesso: Lista os cards das tarefas
  Widget _buildTasksScreen() {
    // Estado de carregamento
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de erro
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTasks,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    // Estado vazio (nenhuma tarefa)
    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nenhuma tarefa encontrada',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            // Para clientes, oferece atalho para criar primeira tarefa
            if (ApiService.currentUserRole == 'cliente') ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1; // Vai para tela de criar tarefa
                  });
                },
                child: const Text('Criar primeira tarefa'),
              ),
            ],
          ],
        ),
      );
    }

    // Estado com tarefas - Lista os cards
    return RefreshIndicator(
      onRefresh: _loadTasks, // Pull to refresh
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return TaskCard(
            task: task,
            userRole: ApiService.currentUserRole ?? '-',
            onTap: () {
              _showTaskDetails(task); // Abre modal com detalhes
            },
            // Apenas admin e dev podem alterar status
            onStatusChange: ApiService.currentUserRole != 'cliente'
                ? () => _showStatusDialog(task)
                : null,
          );
        },
      ),
    );
  }

  /// Exibe um modal com os detalhes completos da tarefa
  /// Utiliza showModalBottomSheet com DraggableScrollableSheet para uma experiência similar a um modal expansível.
  void _showTaskDetails(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o modal ocupe quase toda a tela
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9, // Começa com 90% da tela
          minChildSize: 0.5,      // Mínimo 50%
          maxChildSize: 0.95,     // Máximo 95%
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador de drag (barra no topo)
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
                  
                  // Header com ícone de status e título
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
                  
                  // Seção de descrição
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
                  
                  // Seção de informações adicionais
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

  /// Exibe diálogo para alterar o status de uma tarefa
  /// Disponível apenas para admin e desenvolvedores.
  /// Oferece as 4 opções de status: aberta, em_andamento, concluida, cancelada
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

  /// Constrói uma opção de status no diálogo de alteração
  Widget _buildStatusOption(Task task, String status) {
    final color = _getStatusColor(status);
    return ListTile(
      leading: Icon(_getStatusIcon(status), color: color),
      title: Text(_getStatusText(status)),
      onTap: () async {
        Navigator.pop(context); // Fecha o diálogo
        final result = await ApiService.updateTaskStatus(
          taskId: task.id,
          status: status,
        );
        if (result['success'] == true) {
          _loadTasks(); // Recarrega a lista
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

  /// Constrói uma linha de informação no modal de detalhes
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

  // Verificar situação do status de uma task
  
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
}