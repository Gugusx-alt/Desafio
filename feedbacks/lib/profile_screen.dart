import 'package:flutter/material.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/login_screen.dart';

// Tela de perfil do usuário
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtém os dados do usuário atual através do ApiService
    // Retorna um Map com id, role e token, ou null se não estiver logado
    final user = ApiService.getCurrentUser();
    
    return Center(
      child: Padding(
        // Padding 24 pixels em todos os lados
        padding: const EdgeInsets.all(24),
        child: Column(
          // A coluna ocupa somente o espaço necessário (não se expande).
          mainAxisSize: MainAxisSize.min,
          // Alinha os filhos ao centro horizontalmente
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Círculo com ícone, posteriormente mudar para uma imagem
            CircleAvatar(
              radius: 50, // Tamanho do círculo
              backgroundColor: Colors.blue.shade100, 
              child: Icon(
                Icons.person, // Ícone de pessoa
                size: 50,
                color: Colors.blue.shade700, 
              ),
            ),
            
            const SizedBox(height: 16), // Espaçamento vertical
            
            // Título
            Text(
              'Perfil do Usuário',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Exibe o ID do usuário
            Text(
              'ID: ${user?['id'] ?? '-'}',
              style: const TextStyle(fontSize: 16),
            ),
            
            // Exibe a função do usuário (admin, cliente, desenvolvedor)
            Text(
              'Role: ${user?['role'] ?? '-'}',
              style: const TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 24),
            
            // Botão para realizar o logout 
            ElevatedButton(
              onPressed: () {
                // 1. Limpa os dados de autenticação 
                ApiService.logout();
                
                // 2. Navega para a tela de login
                // pushAndRemoveUntil remove todas as rotas anteriores do histórico
                // (route) => false significa "remove todas as rotas"
                // Isso impede que o usuário volte para o dashboard após o logout
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false, // Remove todo o histórico
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, 
                foregroundColor: Colors.white, 
                minimumSize: const Size(200, 45), // Largura mínima de 200px, altura 45px
              ),
              child: const Text('Sair'),
            ),
          ],
        ),
      ),
    );
  }
}