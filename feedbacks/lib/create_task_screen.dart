import 'package:flutter/material.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/services/application_service.dart';
import 'package:feedbacks/services/refresh_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  // Controladores para os campos de texto
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // ID da aplicação selecionada no dropdown
  int? _selectedApplicationId;
  
  // 🔥 Categoria selecionada
  String _selectedCategory = 'ajuste';
  
  // Controles de estado
  bool _isLoading = false;              
  bool _isLoadingApplications = true;   
  List<Map<String, dynamic>> _applications = [];
  String? _debugInfo;

  // 🔥 Opções de categoria
  final List<Map<String, dynamic>> _categories = [
    {'value': 'bug', 'label': '🐛 Bug', 'color': Colors.red},
    {'value': 'ajuste', 'label': '🔧 Ajuste', 'color': Colors.orange},
    {'value': 'melhoria', 'label': '📈 Melhoria', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }
 
  Future<void> _loadApplications() async {
    setState(() {
      _isLoadingApplications = true;
      _debugInfo = null;
    });

    try {
      final myApplications = await ApplicationService.getMyApplications();
      
      if (!mounted) return;

      setState(() {
        _applications = myApplications.map((app) => {
          'id': app.id,
          'name': app.name,
          'description': app.description,
        }).toList();
        
        _isLoadingApplications = false;
        
        if (_applications.isNotEmpty) {
          _selectedApplicationId = _applications.first['id'] as int;
        } else {
          _debugInfo = 'Você não está vinculado a nenhuma aplicação. Procure o administrador.';
        }
      });
      
      print('✅ Aplicações do usuário carregadas: $_applications');
    } catch (e) {
      print('🔴 Erro ao carregar aplicações: $e');
      
      if (!mounted) return;
      
      setState(() {
        _debugInfo = 'Erro ao carregar aplicações: $e';
        _isLoadingApplications = false;
      });
    }
  }

  Future<void> _handleCreateTask() async {
    // #### VALIDAÇÕES ####
    
    if (_titleController.text.isEmpty) {
      _showErrorSnackBar('Preencha o título da tarefa');
      return;
    }

    if (_selectedApplicationId == null) {
      _showErrorSnackBar('Selecione uma aplicação');
      return;
    }

    // 🔥 VALIDA CATEGORIA
    if (_selectedCategory.isEmpty) {
      _showErrorSnackBar('Selecione uma categoria');
      return;
    }

    if (ApiService.currentUserRole != 'cliente') {
      _showErrorSnackBar('Apenas clientes podem criar tarefas');
      return;
    }

    // #### REQUISIÇÃO ####
    
    setState(() {
      _isLoading = true;
      _debugInfo = null;
    });

    try {
      print('🔵 Enviando requisição para criar tarefa:');
      print('   Título: ${_titleController.text.trim()}');
      print('   Descrição: ${_descriptionController.text.trim()}');
      print('   App ID: $_selectedApplicationId');
      print('   Categoria: $_selectedCategory');
      print('   User ID: ${ApiService.currentUserId}');
      
      final result = await ApiService.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        applicationId: _selectedApplicationId!,
        category: _selectedCategory, // 🔥 ENVIA A CATEGORIA
      );

      print('🟢 Resposta do servidor: $result');

      if (!mounted) return;

      if (result['success'] == true) {
        _titleController.clear();
        _descriptionController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tarefa criada com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        RefreshService().refreshDashboard();
        
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          String errorMsg = 'Erro: ${result['error']}';
          if (result['details'] != null) {
            errorMsg += '\nDetalhes: ${result['details']}';
          }
          _debugInfo = errorMsg;
          _isLoading = false;
        });
        
        _showErrorSnackBar(
          result['error'] ?? 'Erro ao criar tarefa',
        );
      }
    } catch (e, stackTrace) {
      print('🔴 Erro na requisição: $e');
      print('🔴 StackTrace: $stackTrace');
      
      setState(() {
        _debugInfo = 'Exceção: $e';
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      _showErrorSnackBar(
        'Erro de conexão com o servidor',
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
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
      appBar: AppBar(
        title: const Text('Criar tarefa'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth > 500 ? 500.0 : double.infinity;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Nova tarefa',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        
                        // Campo Título
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Título *',
                            border: OutlineInputBorder(),
                            hintText: 'Digite o título da tarefa',
                          ),
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 12),
                        
                        // Campo Descrição
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Descrição (opcional)',
                            border: OutlineInputBorder(),
                            hintText: 'Descreva os detalhes da tarefa...',
                          ),
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 12),
                        
                        // 🔥 DROPDOWN DE CATEGORIA
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Categoria *',
                            border: OutlineInputBorder(),
                          ),
                          items: _categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat['value'],
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: cat['color'],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(cat['label']),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: !_isLoading
                              ? (value) {
                                  setState(() {
                                    _selectedCategory = value!;
                                  });
                                }
                              : null,
                        ),
                        const SizedBox(height: 12),
                        
                        // Dropdown de Aplicações
                        _isLoadingApplications
                            ? const Center(child: CircularProgressIndicator())
                            : _applications.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      border: Border.all(color: Colors.orange.shade200),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Você não está vinculado a nenhuma aplicação',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Procure o administrador para vincular você a uma aplicação.',
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: _loadApplications,
                                          child: const Text('Tentar novamente'),
                                        ),
                                      ],
                                    ),
                                  )
                                : DropdownButtonFormField<int>(
                                    value: _selectedApplicationId,
                                    decoration: const InputDecoration(
                                      labelText: 'Aplicação *',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _applications.map((app) {
                                      return DropdownMenuItem<int>(
                                        value: app['id'] as int,
                                        child: Text(app['name'] as String),
                                      );
                                    }).toList(),
                                    onChanged: !_isLoading
                                        ? (value) {
                                            setState(() {
                                              _selectedApplicationId = value;
                                            });
                                          }
                                        : null,
                                  ),
                        
                        // Área de debug
                        if (_debugInfo != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _debugInfo!,
                              style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Botão Criar
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _applications.isEmpty) ? null : _handleCreateTask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Criar tarefa'),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        Text(
                          'As tarefas aparecem no dashboard agrupadas por status',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}