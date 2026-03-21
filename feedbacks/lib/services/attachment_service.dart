import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/models/attachment.dart';

class AttachmentService {
  static const String baseUrl = ApiService.baseUrl;

  static Future<List<Attachment>> getAttachments(int taskId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/tasks/$taskId/attachments'),
        headers: headers,
      );

      print('🔵 Buscando anexos - Status: ${response.statusCode}');
      print('📦 Resposta anexos: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> attachmentsJson = data['attachments'];
        return attachmentsJson.map((json) => Attachment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔴 Erro ao buscar anexos: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> uploadAttachment(int taskId, http.MultipartFile file) async {
    try {
      final headers = await ApiService.getHeaders();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/tasks/$taskId/attachments'),
      );
      
      request.headers.addAll(headers);
      request.files.add(file);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'error': 'Erro ao enviar'};
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteAttachment(int attachmentId) async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/tasks/attachments/$attachmentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Erro ao excluir'};
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }
}