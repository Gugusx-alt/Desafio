import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/models/application.dart';

class ApplicationManagementService {
  static const String baseUrl = ApiService.baseUrl;

  // Buscar todas as aplicações (admin) com filtro por status
  static Future<List<Application>> getAllApplications({String? status}) async {
    try {
      final headers = await ApiService.getHeaders();
      String url = '$baseUrl/api/applications';
      
      if (status != null && status != 'todos') {
        url += '?status=$status';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> appsJson = data['applications'];
        return appsJson.map((json) => Application.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔴 Erro ao buscar aplicações: $e');
      return [];
    }
  }

  // Atualizar aplicação
  static Future<Map<String, dynamic>> updateApplication({
    required int id,
    required String name,
    String? description,
    String? status,
  }) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final Map<String, dynamic> body = {
        'name': name,
      };
      if (description != null) body['description'] = description;
      if (status != null) body['status'] = status;

      final response = await http.put(
        Uri.parse('$baseUrl/api/applications/$id'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Erro ao atualizar'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // 🔥 ATUALIZADO: Excluir, inativar ou reativar aplicação
  static Future<Map<String, dynamic>> deleteApplication(int id) async {
    try {
      final headers = await ApiService.getHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/applications/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'softDelete': data['softDelete'] ?? false,
          'reativado': data['reativado'] ?? false,
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Erro ao processar'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }
}