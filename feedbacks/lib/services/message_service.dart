import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/models/message.dart';

class MessageService {
  static const String baseUrl = ApiService.baseUrl;

  static Future<List<Message>> getMessages(int taskId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/tasks/$taskId/messages'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messagesJson = data['messages'];
        return messagesJson.map((json) => Message.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar mensagens: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> sendMessage(int taskId, String content) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/tasks/$taskId/messages'),
        headers: headers,
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'error': 'Erro ao enviar mensagem'};
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }
}