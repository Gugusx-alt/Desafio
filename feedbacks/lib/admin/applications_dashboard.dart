import 'package:flutter/material.dart';
import 'package:feedbacks/services/application_service.dart';
import 'package:feedbacks/models/application.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/admin/create_application_screen.dart';
import 'package:feedbacks/admin/users_management_screen.dart';
import 'package:feedbacks/admin/all_applications_screen.dart'; // ← NOVO IMPORT
import 'package:feedbacks/services/refresh_service.dart';
import 'package:feedbacks/login_screen.dart';
import 'dart:async';

class ApplicationsDashboard extends StatefulWidget {
  const ApplicationsDashboard({super.key});

  @override
  State<ApplicationsDashboard> createState() => _ApplicationsDashboardState();
}

class _ApplicationsDashboardState extends State<ApplicationsDashboard> with SingleTickerProviderStateMixin {
  // 0 = Minhas Apps, 1 = Todas Apps, 2 = Usuários
  int _selectedIndex = 0;
  
  // TabController para controlar as abas
  late TabController _tabController;
  
  List<Application> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;
  late StreamSubscription _refreshSubscription;

  @override
  void initState() {
    super.initState();
    
    // Inicializa o TabController com 3 abas
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
    
    _loadApplications();
    
    _refreshSubscription = RefreshService().refreshStream.listen((_) {
      print('🔄 [AppsDashboard] Recarregando aplicações...');
      _loadApplications();
    });
  }

  @override
  void dispose() {
    // Libera o TabController
    _tabController.dispose();
    _refreshSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apps = await ApplicationService.getMyApplications();
    
    if (mounted) {
      setState(() {
        _applications = apps;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteApplication(int id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Aplicação'),
        content: const Text('Tem certeza que deseja excluir esta aplicação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar delete no backend
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aplicação excluída')),
              );
              _loadApplications();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _editApplication(Application app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Aplicação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Nome'),
              controller: TextEditingController(text: app.name),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Descrição'),
              controller: TextEditingController(text: app.description),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aplicação atualizada')),
              );
              _loadApplications();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ApiService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab() {
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
              onPressed: _loadApplications,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apps, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma aplicação criada',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateApplicationScreen(),
                  ),
                );
              },
              child: const Text('Criar primeira aplicação'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _applications.length,
        itemBuilder: (context, index) {
          final app = _applications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple.shade100,
                child: Icon(
                  Icons.apps,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              title: Text(
                app.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(app.description ?? 'Sem descrição'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editApplication(app),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteApplication(app.id),
                  ),
                ],
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(app.name),
                    content: Text(app.description ?? 'Sem descrição'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 
              ? 'Minhas Aplicações' 
              : _selectedIndex == 1 
                  ? 'Todas as Aplicações' 
                  : 'Gerenciar Usuários'
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateApplicationScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.apps), text: 'Minhas Apps'),
            Tab(icon: Icon(Icons.list), text: 'Todas Apps'), // ← NOVA ABA
            Tab(icon: Icon(Icons.people), text: 'Usuários'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ApplicationsTabContent(),    // Minhas aplicações
          AllApplicationsScreen(),       // ← NOVA TELA
          UsersManagementScreen(),       // Gerenciar usuários
        ],
      ),
    );
  }
}

// Widget separado para a tab de aplicações (para evitar reconstrução desnecessária)
class _ApplicationsTabContent extends StatefulWidget {
  const _ApplicationsTabContent({Key? key}) : super(key: key);

  @override
  State<_ApplicationsTabContent> createState() => _ApplicationsTabContentState();
}

class _ApplicationsTabContentState extends State<_ApplicationsTabContent> {
  List<Application> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;

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

    final apps = await ApplicationService.getMyApplications();
    
    if (mounted) {
      setState(() {
        _applications = apps;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteApplication(int id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Aplicação'),
        content: const Text('Tem certeza que deseja excluir esta aplicação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar delete no backend
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aplicação excluída')),
              );
              _loadApplications();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _editApplication(Application app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Aplicação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Nome'),
              controller: TextEditingController(text: app.name),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Descrição'),
              controller: TextEditingController(text: app.description),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aplicação atualizada')),
              );
              _loadApplications();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _loadApplications,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apps, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Crie sua aplicação',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateApplicationScreen(),
                  ),
                );
              },
              child: const Text('Criar primeira aplicação'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _applications.length,
        itemBuilder: (context, index) {
          final app = _applications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple.shade100,
                child: Icon(
                  Icons.apps,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              title: Text(
                app.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(app.description ?? 'Sem descrição'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editApplication(app),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteApplication(app.id),
                  ),
                ],
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(app.name),
                    content: Text(app.description ?? 'Sem descrição'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}