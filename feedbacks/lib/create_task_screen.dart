import 'package:flutter/material.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/services/application_service.dart'; // NOVO IMPORT
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
  
  // Controles de estado
  bool _isLoading = false;              
  bool _isLoadingApplications = true;   
  List<Map<String, dynamic>> _applications = []; // Lista de aplicações
  String? _debugInfo;                    

  @override
  void initState() {
    super.initState();
    _loadApplications(); // Carrega aplicações ao iniciar a tela
  }
 
  /// Carrega APENAS as aplicações que o usuário tem acesso
  /// Agora usando ApplicationService.getMyApplications()
  Future<void> _loadApplications() async {
    setState(() {
      _isLoadingApplications = true;
      _debugInfo = null;
    });

    try {
      // 🔥 MUDANÇA: Agora usa ApplicationService que filtra por usuário
      final myApplications = await ApplicationService.getMyApplications();
      
      if (!mounted) return;

      setState(() {
        // Converte a lista de Application para o formato Map que o dropdown espera
        _applications = myApplications.map((app) => {
          'id': app.id,
          'name': app.name,
          'description': app.description,
        }).toList();
        
        _isLoadingApplications = false;
        
        if (_applications.isNotEmpty) {
          // Seleciona a primeira aplicação por padrão
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
      print('   User ID: ${ApiService.currentUserId}');
      
      final result = await ApiService.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        applicationId: _selectedApplicationId!,
      );

      print('🟢 Resposta do servidor: $result');

      if (!mounted) return;

      if (result['success'] == true) {
        // SUCESSO: Limpa campos e mostra mensagem verde
        _titleController.clear();
        _descriptionController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tarefa criada com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 🔥 DISPARA A ATUALIZAÇÃO EM TEMPO REAL
        RefreshService().refreshDashboard();
        
        // PERMANECE NA TELA para criar mais tarefas
        setState(() {
          _isLoading = false;
        });
      } else {
        // ERRO: Mostra detalhes e mensagem vermelha
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
      // ERRO DE CONEXÃO
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

  /// Exibe um SnackBar de erro com fundo vermelho
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Libera recursos dos controladores quando a tela é destruída
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
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsividade: limita largura máxima em telas grandes
                final maxWidth =
                    constraints.maxWidth > 500 ? 500.0 : double.infinity;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Título da tela
                        const Text(
                          'Nova tarefa',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Campo para colocar o título da task
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
                        
                        // Campo para colocar uma descrição da task
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
                        
                        // #### DROPDOWN DE APLICAÇÕES (AGORA FILTRADO) ####
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
                        
                        // #### ÁREA DE DEBUG (VISÍVEL APENAS EM ERRO) ####
                        if (_debugInfo != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Informações de debug:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _debugInfo!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Botão para criar a tarefa
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _applications.isEmpty) ? null : _handleCreateTask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Criando...'),
                                    ],
                                  )
                                : const Text('Criar tarefa'),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // informações do rodapé
                        Text(
                          'As tarefas aparecem no dashboard para todos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
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