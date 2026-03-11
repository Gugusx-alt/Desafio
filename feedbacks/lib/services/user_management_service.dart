import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:feedbacks/services/api_service.dart';

class UserManagementService {
  static const String baseUrl = ApiService.baseUrl;

  // Buscar todos os usuários (apenas admin)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final headers = await ApiService.getHeaders();
      print('🔵 Buscando todos os usuários');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: headers,
      );

      print('🟢 Status: ${response.statusCode}');
      print('📦 Resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['users']);
      }
      return [];
    } catch (e) {
      print('🔴 Erro ao buscar usuários: $e');
      return [];
    }
  }

  // Excluir usuário (apenas admin)
  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    if (ApiService.currentUserRole != 'admin') {
      return {'success': false, 'error': 'Apenas admin pode excluir usuários'};
    }

    try {
      final headers = await ApiService.getHeaders();
      print('🔵 Excluindo usuário $userId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: headers,
      );

      print('🟢 Status exclusão: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Erro ao excluir'};
      }
    } catch (e) {
      print('🔴 Erro na exclusão: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }
}