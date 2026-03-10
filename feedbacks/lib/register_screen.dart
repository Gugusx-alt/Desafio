import 'package:flutter/material.dart';
import 'package:feedbacks/services/api_service.dart';

/// Tela de cadastro de novos usuários
/// 
/// Esta tela permite que novos usuários se registrem no sistema,
/// fornecendo suas informações básicas e escolhendo seu papel (role)
/// na plataforma: admin, cliente ou desenvolvedor.
/// 
/// Funcionalidades:
/// - Validação de campos obrigatórios
/// - Confirmação de senha
/// - Seleção de tipo de usuário via dropdown
/// - Integração com ApiService.register() para criar a conta
/// - Feedback visual durante o processo de cadastro
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores para os campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Role selecionada no dropdown (padrão: 'cliente')
  String _selectedRole = 'cliente';
  
  // Controle de estado de loading (desativa botões durante requisição)
  bool _isLoading = false;

  /// Processa o cadastro do usuário
  /// 
  /// Etapas:
  /// 1. Valida se todos os campos estão preenchidos
  /// 2. Verifica se as senhas coincidem
  /// 3. Verifica tamanho mínimo da senha (6 caracteres)
  /// 4. Chama ApiService.register() para criar a conta
  /// 5. Exibe feedback de sucesso/erro
  /// 6. Em caso de sucesso, retorna para a tela de login
  Future<void> _handleRegister() async {
  
    
    // Verifica campos vazios
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    // Verifica se as senhas coincidem
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem')),
      );
      return;
    }

    // Verifica tamanho mínimo da senha
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A senha deve ter pelo menos 6 caracteres')),
      );
      return;
    }

    // #### REQUISIÇÃO ####
    
    // Ativa estado de loading (desativa botões)
    setState(() => _isLoading = true);

    // Chama API de registro
    final result = await ApiService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    // Desativa estado de loading
    setState(() => _isLoading = false);

    
    
    if (result['success'] == true) {
      // mostra mensagem e volta para login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso!'),
            backgroundColor: Colors.green, 
          ),
        );
        Navigator.of(context).pop(); // Volta para tela de login
      }
    } else {
      // mostra mensagem de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erro no cadastro'),
            backgroundColor: Colors.red, 
          ),
        );
      }
    }
  }

  /// Libera recursos dos controladores quando a tela é destruída
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // limita largura máxima em telas grandes
                final maxWidth =
                    constraints.maxWidth > 500 ? 400.0 : double.infinity;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // título
                        const Text(
                          'Cadastro',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // campo para inserir o nome 
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            border: OutlineInputBorder(),
                            hintText: 'Digite seu nome completo',
                          ),
                          enabled: !_isLoading, // Desabilita durante loading
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // campo para inserir o email 
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            border: OutlineInputBorder(),
                            hintText: 'exemplo@email.com',
                          ),
                          enabled: !_isLoading,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // campo para inserir a senha 
                        TextField(
                          controller: _passwordController,
                          obscureText: true, // Oculta a senha
                          decoration: const InputDecoration(
                            labelText: 'Senha',
                            border: OutlineInputBorder(),
                            hintText: 'Mínimo 6 caracteres',
                          ),
                          enabled: !_isLoading,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // campo de confirmar senha 
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar senha',
                            border: OutlineInputBorder(),
                            hintText: 'Digite a senha novamente',
                          ),
                          enabled: !_isLoading,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Parte para selecionar o role/cargo
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de usuário',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'cliente',
                              child: Text('Cliente'),
                            ),
                            DropdownMenuItem(
                              value: 'desenvolvedor',
                              child: Text('Desenvolvedor'),
                            ),
                          ],
                          onChanged: _isLoading
                              ? null // Desabilita durante loading
                              : (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedRole = value;
                                    });
                                  }
                                },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // botão para realizar o cadastro
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Cadastrar'),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // voltar para o login
                        TextButton(
                          onPressed: _isLoading
                              ? null 
                              : () {
                                  Navigator.of(context).pop();
                                },
                          child: const Text('Já tenho conta (voltar pro login)'),
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