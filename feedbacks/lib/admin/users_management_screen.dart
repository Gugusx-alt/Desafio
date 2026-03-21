import 'package:flutter/material.dart';
import 'package:feedbacks/services/user_management_service.dart';
import 'package:feedbacks/services/refresh_service.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/admin/edit_user_screen.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'todos';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final status = _statusFilter == 'todos' ? null : _statusFilter;
    final users = await UserManagementService.getAllUsers(status: status);
    
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) =>
      user['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
      user['email'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _handleUserAction(Map<String, dynamic> user) async {
    if (user['id'] == ApiService.currentUserId) {
      _showMessage('Você não pode alterar seu próprio usuário', isError: true);
      return;
    }

    final isInactive = user['status'] == 'inativo';
    final taskCount = user['task_count'] ?? 0;
    final hasTasks = taskCount > 0;

    String title, content, buttonText;
    Color buttonColor;

    if (isInactive) {
      title = 'Reativar usuário';
      content = 'Deseja reativar "${user['name']}"?';
      buttonText = 'Reativar';
      buttonColor = Colors.green;
    } else if (hasTasks) {
      title = 'Inativar usuário';
      content = '${user['name']} possui $taskCount tarefa(s).\n\nDeseja inativar este usuário?';
      buttonText = 'Inativar';
      buttonColor = Colors.orange;
    } else {
      title = 'Excluir usuário';
      content = 'Deseja excluir "${user['name']}" permanentemente?';
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

    final result = await UserManagementService.deleteUser(user['id']);

    if (!mounted) return;

    if (result['success']) {
      String msg;
      if (result['reativado'] == true) {
        msg = 'Usuário reativado';
      } else if (result['softDelete'] == true) {
        msg = 'Usuário inativado';
      } else {
        msg = 'Usuário excluído';
      }
      _showMessage(msg);
      _loadUsers();
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

  void _editUser(Map<String, dynamic> user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditUserScreen(user: user)),
    );
    if (result == true) _loadUsers();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.purpleAccent;
      case 'cliente': return Colors.lightBlueAccent;
      case 'desenvolvedor': return Colors.lightGreenAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detecta se o tema é escuro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Campo de busca
                TextField(
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou e-mail...',
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
                // Botões de filtro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFilterChip('Todos', 'todos', Colors.grey, isDarkMode),
                    const SizedBox(width: 8),
                    _buildFilterChip('Ativos', 'ativo', Colors.green, isDarkMode),
                    const SizedBox(width: 8),
                    _buildFilterChip('Inativos', 'inativo', Colors.red, isDarkMode),
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
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                            size: 48,
                            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty 
                                ? 'Nenhum usuário cadastrado' 
                                : 'Nenhum usuário encontrado',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isCurrentUser = user['id'] == ApiService.currentUserId;
                          final isInactive = user['status'] == 'inativo';
                          final taskCount = user['task_count'] ?? 0;
                          final hasTasks = taskCount > 0;

                          return Card(
                            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: _getRoleColor(user['role']).withOpacity(0.2),
                                child: Text(
                                  user['name'][0].toUpperCase(),
                                  style: TextStyle(
                                    color: _getRoleColor(user['role']),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              title: Text(
                                user['name'],
                                style: TextStyle(
                                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
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
                                  Text(
                                    user['email'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isInactive 
                                          ? (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500)
                                          : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getRoleColor(user['role']).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          user['role'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _getRoleColor(user['role']),
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
                                              '$taskCount',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: isCurrentUser
                                  ? null
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, size: 20, color: Colors.blue.shade400),
                                          onPressed: () => _editUser(user),
                                          tooltip: 'Editar',
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isInactive ? Icons.restore : (hasTasks ? Icons.block : Icons.delete),
                                            size: 20,
                                            color: isInactive 
                                                ? Colors.green.shade400
                                                : (hasTasks ? Colors.orange.shade400 : Colors.red.shade400),
                                          ),
                                          onPressed: () => _handleUserAction(user),
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
        _loadUsers();
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