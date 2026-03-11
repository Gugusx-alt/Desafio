import 'package:flutter/material.dart';
import 'package:feedbacks/services/application_service.dart';
import 'package:feedbacks/services/refresh_service.dart';

class CreateApplicationScreen extends StatefulWidget {
  const CreateApplicationScreen({super.key});

  @override
  State<CreateApplicationScreen> createState() => _CreateApplicationScreenState();
}

class _CreateApplicationScreenState extends State<CreateApplicationScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingUsers = true;
  
  List<Map<String, dynamic>> _users = [];
  List<int> _selectedUserIds = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await ApplicationService.getAllUsers();
    if (mounted) {
      setState(() {
        // Filtra apenas usuários que não são admin (clientes e devs)
        _users = users.where((user) => user['role'] != 'admin').toList();
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _createApplication() async {
    // Validação do nome
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome da aplicação é obrigatório'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validação de usuários selecionados
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um usuário'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Cria a aplicação (o admin é auto-vinculado no backend)
      final result = await ApplicationService.createApplication(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final appId = result['data']['application']['id'];
        
        // 2. Vincula os usuários selecionados
        bool allLinked = true;
        
        for (var userId in _selectedUserIds) {
          final linkResult = await ApplicationService.linkUserToApplication(
            applicationId: appId,
            userId: userId,
            roleInApp: 'cliente', // Usuários comuns são clientes por padrão
          );
          
          if (!linkResult['success']) {
            allLinked = false;
            print('❌ Erro ao vincular usuário $userId: ${linkResult['error']}');
          }
        }

        // Feedback de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              allLinked 
                  ? '✅ Aplicação criada e todos os usuários vinculados!'
                  : '⚠️ Aplicação criada, mas alguns usuários não foram vinculados',
            ),
            backgroundColor: allLinked ? Colors.green : Colors.orange,
          ),
        );
        
        // Atualiza o dashboard
        RefreshService().refreshDashboard();
        
        // Volta para o dashboard
        Navigator.pop(context, true);
        
      } else {
        // Erro ao criar aplicação
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error'] ?? 'Erro ao criar aplicação'}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Erro inesperado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Aplicação'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card com campos da aplicação
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Campo Nome
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome da Aplicação *',
                              border: OutlineInputBorder(),
                              hintText: 'Ex: Sistema de Vendas',
                            ),
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),
                          
                          // Campo Descrição
                          TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Descrição (opcional)',
                              border: OutlineInputBorder(),
                              hintText: 'Descreva o propósito da aplicação...',
                            ),
                            enabled: !_isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Título da seção de usuários
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.deepPurple.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Selecionar Usuários',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Contador de selecionados
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedUserIds.length} usuário(s) selecionado(s)',
                      style: TextStyle(
                        color: Colors.deepPurple.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Lista de usuários
                  Expanded(
                    child: _users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhum usuário disponível',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              final isSelected = _selectedUserIds.contains(user['id']);
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: CheckboxListTile(
                                  title: Text(
                                    user['name'],
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${user['email']} • ${user['role']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  value: isSelected,
                                  onChanged: !_isLoading
                                      ? (value) {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedUserIds.remove(user['id']);
                                            } else {
                                              _selectedUserIds.add(user['id']);
                                            }
                                          });
                                        }
                                      : null,
                                  secondary: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? Colors.green.shade100
                                        : Colors.grey.shade200,
                                    child: Text(
                                      user['name'][0].toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.green.shade700
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botão Criar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _isLoadingUsers) ? null : _createApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Criar Aplicação',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}