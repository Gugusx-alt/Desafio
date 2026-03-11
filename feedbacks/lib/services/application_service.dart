import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/models/application.dart';

class ApplicationService {
  static const String baseUrl = ApiService.baseUrl;

  // Método auxiliar para pegar headers (usa o método público do ApiService)
  static Future<Map<String, String>> _getHeaders() async {
    return await ApiService.getHeaders();
  }

  // Buscar APENAS as aplicações que o usuário tem acesso
  static Future<List<Application>> getMyApplications() async {
    try {
      final headers = await _getHeaders();
      print('🔵 Buscando aplicações do usuário ${ApiService.currentUserId}');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/applications/my'),
        headers: headers,
      );

      print('🟢 Status: ${response.statusCode}');
      print('📦 Resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> appsJson = data['applications'];
        return appsJson.map((json) => Application.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔴 Erro ao buscar minhas aplicações: $e');
      return [];
    }
  }

  // 🔥 NOVO: Buscar TODAS as aplicações (apenas admin)
  static Future<List<Application>> getAllApplications() async {
    if (ApiService.currentUserRole != 'admin') {
      print('⚠️ Apenas admin pode ver todas as aplicações');
      return [];
    }

    try {
      final headers = await _getHeaders();
      print('🔵 Buscando TODAS as aplicações');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/applications'),
        headers: headers,
      );

      print('🟢 Status: ${response.statusCode}');
      print('📦 Resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> appsJson = data['applications'];
        return appsJson.map((json) => Application.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔴 Erro ao buscar todas as aplicações: $e');
      return [];
    }
  }

  // Admin: Criar aplicação
  static Future<Map<String, dynamic>> createApplication({
    required String name,
    String? description,
  }) async {
    if (ApiService.currentUserRole != 'admin') {
      return {'success': false, 'error': 'Apenas admin pode criar aplicações'};
    }

    try {
      final headers = await _getHeaders();
      print('🔵 Criando aplicação: $name');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/applications'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      print('🟢 Status criação: ${response.statusCode}');
      print('📦 Resposta criação: ${response.body}');

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Erro ao criar aplicação'};
      }
    } catch (e) {
      print('🔴 Erro na criação: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // Admin: Vincular usuário a uma aplicação
  static Future<Map<String, dynamic>> linkUserToApplication({
    required int applicationId,
    required int userId,
    required String roleInApp,
  }) async {
    if (ApiService.currentUserRole != 'admin') {
      return {'success': false, 'error': 'Apenas admin pode vincular usuários'};
    }

    try {
      final headers = await _getHeaders();
      print('🔵 Vinculando usuário $userId à aplicação $applicationId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/applications/$applicationId/users'),
        headers: headers,
        body: jsonEncode({
          'userId': userId,
          'roleInApp': roleInApp,
        }),
      );

      print('🟢 Status vínculo: ${response.statusCode}');
      print('📦 Resposta vínculo: ${response.body}');

      if (response.statusCode == 201) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Erro ao vincular usuário'};
      }
    } catch (e) {
      print('🔴 Erro no vínculo: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // Admin: Buscar todos os usuários (para vincular)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final headers = await _getHeaders();
      print('🔵 Buscando todos os usuários');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: headers,
      );

      print('🟢 Status usuários: ${response.statusCode}');
      print('📦 Resposta usuários: ${response.body}');

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
}