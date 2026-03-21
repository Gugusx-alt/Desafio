import 'package:flutter/material.dart';
import 'package:feedbacks/create_task_screen.dart';
import 'package:feedbacks/admin/applications_dashboard.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/tasks/tasks_dashboard.dart';
import 'package:feedbacks/widgets/task_detail_screen.dart';
import 'package:feedbacks/models/task.dart';
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
  
  late StreamSubscription _refreshSubscription;

  @override
  void initState() {
    super.initState();
    
    _refreshSubscription = RefreshService().refreshStream.listen((_) {
      print('🔄 [Dashboard] Stream recebido! Recarregando...');
    });
  }

  @override
  void dispose() {
    _refreshSubscription.cancel();
    super.dispose();
  }

  // Método para exibir o modal de detalhes da tarefa
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
                  // Indicador de drag
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
                            const SizedBox(height: 4),
                            // Categoria
                            Row(
                              children: [
                                Icon(task.categoryIcon, size: 14, color: task.categoryColor),
                                const SizedBox(width: 4),
                                Text(
                                  task.categoryText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: task.categoryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Descrição
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
                  
                  // Informações
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
                  // 🔥 MOSTRA O NOME DO CRIADOR EM VEZ DO ID
                  _buildInfoRow('Criado por', task.createdByName ?? 'Usuário #${task.createdBy}'),
                  if (task.assignedTo != null)
                    _buildInfoRow('Atribuído para', 'Usuário #${task.assignedTo}'),
                  _buildInfoRow('Criado em', _formatDate(task.createdAt)),
                  if (task.updatedAt != null)
                    _buildInfoRow('Atualizado em', _formatDate(task.updatedAt!)),
                  
                  const SizedBox(height: 24),
                  
                  // Botão para abrir chat e anexos
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Fecha o modal
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailScreen(task: task),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Abrir Chat e Anexos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Método para formatar texto do status
  String _getStatusText(String status) {
    switch (status) {
      case 'aberta': return 'Aberta';
      case 'em_andamento': return 'Em Andamento';
      case 'concluida': return 'Concluída';
      case 'cancelada': return 'Cancelada';
      default: return status;
    }
  }

  // Método para formatar data
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Método para construir linha de informação
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
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
      case 0: // Dashboard (mostra tarefas agrupadas)
        return const TasksDashboard(); // Usa a nova tela de tarefas
      
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
} 