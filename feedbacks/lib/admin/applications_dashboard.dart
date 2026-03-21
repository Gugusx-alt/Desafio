import 'package:flutter/material.dart';
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
  State<ApplicationsDashboard> createState() => _ApplicationsDashboardState();
}

class _ApplicationsDashboardState extends State<ApplicationsDashboard> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  late StreamSubscription _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
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
            Tab(icon: Icon(Icons.list), text: 'Todas Apps'),
            Tab(icon: Icon(Icons.people), text: 'Usuários'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MyApplicationsManagementScreen(),
          AllApplicationsScreen(),
          UsersManagementScreen(),
        ],
      ),
    );
  }
}

// 🔥 TELA DE GERENCIAMENTO DE APLICAÇÕES (Minhas Apps)
class MyApplicationsManagementScreen extends StatefulWidget {
  const MyApplicationsManagementScreen({super.key});

  @override
  State<MyApplicationsManagementScreen> createState() => _MyApplicationsManagementScreenState();
}

class _MyApplicationsManagementScreenState extends State<MyApplicationsManagementScreen> {
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

  // 🔥 ATUALIZADO: Busca TODAS as aplicações do admin (ativas e inativas)
  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apps = await ApplicationService.getMyAllApplications();
    
    print('📊 Aplicações carregadas: ${apps.length}');
    for (var app in apps) {
      print('   - ${app.name}: status=${app.status}, taskCount=${app.taskCount}');
    }
    
    if (mounted) {
      setState(() {
        _applications = apps;
        _isLoading = false;
      });
    }
  }

  List<Application> get _filteredApplications {
    List<Application> filtered = _applications;
    
    // Filtro por status
    if (_statusFilter != 'todos') {
      filtered = filtered.where((app) => app.status == _statusFilter).toList();
    }
    
    // Filtro por busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((app) =>
        app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (app.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    return filtered;
  }

  Future<void> _handleApplicationAction(Application app) async {
    final isInactive = app.status == 'inativo';
    final hasTasks = (app.taskCount ?? 0) > 0;

    String title, content, buttonText;
    Color buttonColor;

    if (isInactive) {
      title = 'Reativar aplicação';
      content = 'Deseja reativar "${app.name}"?\n\nEla voltará a ficar disponível para criação de tarefas.';
      buttonText = 'Reativar';
      buttonColor = Colors.green;
    } else if (hasTasks) {
      title = 'Inativar aplicação';
      content = '${app.name} possui ${app.taskCount} tarefa(s) vinculada(s).\n\n'
          'Deseja INATIVAR esta aplicação?\n\n'
          'Ela não poderá receber novas tarefas, mas as existentes permanecerão.';
      buttonText = 'Inativar';
      buttonColor = Colors.orange;
    } else {
      title = 'Excluir aplicação';
      content = 'Deseja EXCLUIR PERMANENTEMENTE "${app.name}"?\n\n'
          'Ela não possui tarefas vinculadas. Esta ação não pode ser desfeita.';
      buttonText = 'Excluir';
      buttonColor = Colors.red;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: buttonColor),
            child: Text(buttonText),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final result = await ApplicationManagementService.deleteApplication(app.id);

    if (!mounted) return;

    if (result['success']) {
      String msg;
      if (result['reativado'] == true) {
        msg = '✅ "${app.name}" reativada com sucesso!';
      } else if (result['softDelete'] == true) {
        msg = '⚠️ "${app.name}" inativada (possui ${app.taskCount} tarefa(s) vinculada(s))';
      } else {
        msg = '🗑️ "${app.name}" excluída permanentemente';
      }
      _showMessage(msg);
      _loadApplications();
      RefreshService().refreshDashboard();
    } else {
      _showMessage(result['error'] ?? 'Erro', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _editApplication(Application app) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditApplicationScreen(application: app),
      ),
    );
    if (result == true) _loadApplications();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Aplicações'),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou descrição...',
                    hintStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                    prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white70 : Colors.deepPurple.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFilterChip('Todas', 'todos', Colors.grey, isDarkMode),
                    const SizedBox(width: 8),
                    _buildFilterChip('Ativas', 'ativo', Colors.green, isDarkMode),
                    const SizedBox(width: 8),
                    _buildFilterChip('Inativas', 'inativo', Colors.red, isDarkMode),
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
              : _filteredApplications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.apps : Icons.search_off,
                            size: 48,
                            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty 
                                ? 'Nenhuma aplicação cadastrada' 
                                : 'Nenhuma aplicação encontrada',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          if (_searchQuery.isEmpty)
                            const SizedBox(height: 16),
                          if (_searchQuery.isEmpty)
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
                    )
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredApplications.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApplications[index];
                          final isInactive = app.status == 'inativo';
                          final hasTasks = (app.taskCount ?? 0) > 0;

                          return Card(
                            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isInactive 
                                    ? (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300)
                                    : Colors.deepPurple.withOpacity(0.2),
                                child: Icon(
                                  Icons.apps,
                                  color: isInactive 
                                      ? (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600)
                                      : Colors.deepPurple,
                                ),
                              ),
                              title: Text(
                                app.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  decoration: isInactive ? TextDecoration.lineThrough : null,
                                  color: isInactive 
                                      ? (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600)
                                      : (isDarkMode ? Colors.white : Colors.black87),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (app.description != null && app.description!.isNotEmpty)
                                    Text(
                                      app.description!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isInactive 
                                              ? (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)
                                              : Colors.deepPurple.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          app.status == 'ativo' ? 'Ativa' : 'Inativa',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isInactive 
                                                ? (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)
                                                : Colors.deepPurple,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.assignment,
                                              size: 12,
                                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${app.taskCount ?? 0}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'ID: ${app.id}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, size: 20, color: Colors.blue.shade400),
                                    onPressed: () => _editApplication(app),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isInactive ? Icons.restore : (hasTasks ? Icons.block : Icons.delete_outline),
                                      size: 20,
                                      color: isInactive 
                                          ? Colors.green.shade400
                                          : (hasTasks ? Colors.orange.shade400 : Colors.red.shade400),
                                    ),
                                    onPressed: () => _handleApplicationAction(app),
                                    tooltip: isInactive ? 'Reativar' : (hasTasks ? 'Inativar' : 'Excluir'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color, bool isDarkMode) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? color : (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _statusFilter = value);
        _loadApplications();
      },
      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
      selectedColor: color.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? color : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
        width: 1,
      ),
      shape: const StadiumBorder(),
    );
  }
}