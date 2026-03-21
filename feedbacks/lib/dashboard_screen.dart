import 'package:flutter/material.dart';
import 'package:feedbacks/create_task_screen.dart';
import 'package:feedbacks/admin/applications_dashboard.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/tasks/tasks_dashboard.dart'; // NOVO IMPORT
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
        return const TasksDashboard(); // 🔥 USANDO A NOVA TELA
      
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