import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:feedbacks/services/api_service.dart';

class UserManagementService {
  static const String baseUrl = ApiService.baseUrl;

  // Buscar todos os usuários (com filtro opcional por status)
  static Future<List<Map<String, dynamic>>> getAllUsers({String? status}) async {
    try {
      final headers = await ApiService.getHeaders();
      String url = '$baseUrl/api/users';
      
      if (status != null && status != 'todos') {
        url += '?status=$status';
      }
      
      print('🔵 Buscando usuários com status: $status');
      
      final response = await http.get(
        Uri.parse(url),
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

  // Buscar usuário por ID
  static Future<Map<String, dynamic>?> getUserById(int userId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'];
      }
      return null;
    } catch (e) {
      print('🔴 Erro ao buscar usuário: $e');
      return null;
    }
  }

  // Criar usuário
  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String status = 'ativo',
  }) async {
    if (ApiService.currentUserRole != 'admin') {
      return {'success': false, 'error': 'Apenas admin pode criar usuários'};
    }

    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'phone': phone,
          'status': status,
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Erro ao criar usuário'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // Atualizar usuário
  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? name,
    String? email,
    String? password,
    String? role,
    String? phone,
    String? status,
  }) async {
    if (ApiService.currentUserRole != 'admin') {
      return {'success': false, 'error': 'Apenas admin pode editar usuários'};
    }

    try {
      final headers = await ApiService.getHeaders();
      
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (password != null) body['password'] = password;
      if (role != null) body['role'] = role;
      if (phone != null) body['phone'] = phone;
      if (status != null) body['status'] = status;

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Erro ao atualizar usuário'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // 🔥 ATUALIZADO: Excluir, inativar ou reativar usuário
  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    if (ApiService.currentUserRole != 'admin') {
      return {'success': false, 'error': 'Apenas admin pode gerenciar usuários'};
    }

    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: headers,
      );

      print('🟢 Status exclusão: ${response.statusCode}');
      print('📦 Resposta exclusão: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'softDelete': data['softDelete'] ?? false,
          'reativado': data['reativado'] ?? false, // 🔥 NOVO: indica se foi reativado
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Erro ao processar'};
      }
    } catch (e) {
      print('🔴 Erro na exclusão: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }
}