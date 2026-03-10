import 'package:flutter/material.dart';
import 'package:feedbacks/register_screen.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/dashboard_screen.dart';

/// Tela de login 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para os campos de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Controle de estado de loading (desativa botões durante requisição)
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    // validação 
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    
    // Ativa loading
    setState(() => _isLoading = true);

    // Chama API de login
    final result = await ApiService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    // Desativa loading
    setState(() => _isLoading = false);

    
    if (result['success'] == true) {
      // mostra mensagem de boas-vindas e vai para Dashboard
      if (mounted) {
        // Pega o nome do usuário da resposta da API
        final userName = result['data']['user']['name'] ?? 'Usuário';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login feito! Bem-vindo, $userName'),
            backgroundColor: Colors.green, // Verde para sucesso
          ),
        );
        
        // pushReplacement substitui a tela atual (login) pela Dashboard
        // Isso impede que o usuário volte para o login com o botão "voltar"
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      }
    } else {
      // Erro: mostra mensagem de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erro no login'),
            backgroundColor: Colors.red, 
          ),
        );
      }
    }
  }

  /// Libera recursos dos controladores quando a tela é destruída
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                // Em telas >500px, o formulário terá no máximo 400px de largura
                final maxWidth = constraints.maxWidth > 500 ? 400.0 : double.infinity;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // título
                        const Text(
                          'Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Campo para inserir o email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            border: OutlineInputBorder(),
                            hintText: 'exemplo@email.com',
                          ),
                          enabled: !_isLoading, // Desabilita durante loading
                          // Aciona login ao pressionar "Enter" no teclado
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Campo para inserir senha 
                        TextField(
                          controller: _passwordController,
                          obscureText: true, // Oculta a senha
                          decoration: const InputDecoration(
                            labelText: 'Senha',
                            border: OutlineInputBorder(),
                            hintText: 'Digite sua senha',
                          ),
                          enabled: !_isLoading,
                          // Aciona login ao pressionar "Enter" no teclado
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Botão para o login
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Entrar'),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // TextButton para ir para o cadastro
                        TextButton(
                          onPressed: _isLoading
                              ? null // Desabilita durante loading
                              : () {
                                  // Navega para tela de registro
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterScreen(),
                                    ),
                                  );
                                },
                          child: const Text('Criar conta'),
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