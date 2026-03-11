import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Simples armazenamento em memória do usuário logado
  static String? authToken;
  static int? currentUserId;
  static String? currentUserRole;

  static const String baseUrl = 'http://localhost:3000';

  // Headers padrão para requisições autenticadas
  static Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }

  // 🔥 NOVO MÉTODO PÚBLICO para outros serviços acessarem os headers
  static Future<Map<String, String>> getHeaders() async {
    return await _getHeaders();
  }

  // Teste de conexão simples
  static Future<String> testConnection() async {
    try {
      print('🔵 Testando conexão com: $baseUrl/api/health');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
      ).timeout(const Duration(seconds: 5));
      
      print('🟢 Resposta do servidor: ${response.statusCode}');
      print('📦 Corpo: ${response.body}');
      
      if (response.statusCode == 200) {
        return 'Conectado (${response.statusCode})';
      } else {
        return 'Erro ${response.statusCode}';
      }
    } catch (e) {
      print('🔴 Erro no teste de conexão: $e');
      throw Exception('Falha na conexão: $e');
    }
  }

  // Cadastro
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      print('🔵 Enviando requisição de registro para: $baseUrl/api/auth/register');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10));

      print('🟢 Status code: ${response.statusCode}');
      print('📦 Resposta: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Erro no cadastro'};
      }
    } catch (e) {
      print('🔴 Erro no registro: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 Enviando requisição de login para: $baseUrl/api/auth/login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      print('🟢 Status code: ${response.statusCode}');
      print('📦 Resposta: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Guarda token e infos básicas do usuário em memória
        authToken = data['token'] as String?;
        final user = data['user'] as Map<String, dynamic>?;
        if (user != null) {
          currentUserId = user['id'] as int?;
          currentUserRole = user['role'] as String?;
        }
        
        print('✅ Login bem-sucedido:');
        print('   Token: ${authToken?.substring(0, 20)}...');
        print('   User ID: $currentUserId');
        print('   Role: $currentUserRole');
        
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Erro no login'};
      }
    } catch (e) {
      print('🔴 Erro no login: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // Buscar aplicações
  static Future<List<Map<String, dynamic>>> getApplications() async {
    try {
      final headers = await _getHeaders();
      print('🔵 Buscando aplicações...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/applications'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      print('🟢 Status: ${response.statusCode}');
      print('📦 Resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final applications = List<Map<String, dynamic>>.from(data['applications']);
        print('✅ Aplicações carregadas: $applications');
        return applications;
      }
      return [];
    } catch (e) {
      print('🔴 Erro ao buscar aplicações: $e');
      return [];
    }
  }

  // Criar tarefa
  static Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    required int applicationId,
  }) async {
    if (currentUserId == null) {
      print('🔴 Erro: currentUserId é null');
      return {
        'success': false,
        'error': 'Usuário não identificado. Faça login novamente.',
      };
    }

    if (authToken == null) {
      print('🔴 Erro: authToken é null');
      return {
        'success': false,
        'error': 'Token de autenticação não encontrado. Faça login novamente.',
      };
    }

    try {
      final headers = await _getHeaders();
      
      // Body no formato CAMELCASE que o controller espera
      final Map<String, dynamic> body = {
        'title': title,
        'applicationId': applicationId,
        'createdBy': currentUserId,
      };

      // Adiciona description apenas se não for vazia
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }
      
      print('🔵 Enviando requisição para criar tarefa:');
      print('   URL: $baseUrl/api/tasks');
      print('   Headers: $headers');
      print('   Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/api/tasks'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      print('🟢 Status code: ${response.statusCode}');
      print('📦 Resposta bruta: ${response.body}');

      // Tenta parsear o JSON mesmo em caso de erro
      dynamic data;
      try {
        data = jsonDecode(response.body);
        print('📦 JSON parseado: $data');
      } catch (e) {
        print('🔴 Erro ao parsear JSON: $e');
        return {
          'success': false,
          'error': 'Resposta inválida do servidor: ${response.body}',
          'statusCode': response.statusCode,
        };
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Erro ao criar tarefa',
          'statusCode': response.statusCode,
          'details': data,
        };
      }
    } catch (e) {
      print('🔴 Erro na requisição: $e');
      return {
        'success': false,
        'error': 'Erro de conexão: $e',
      };
    }
  }

  // Buscar tarefas do usuário atual (filtradas por created_by)
  static Future<Map<String, dynamic>> getTasks() async {
    if (currentUserId == null) {
      return {'success': false, 'error': 'Usuário não logado'};
    }

    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/tasks'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      print('🟢 Buscando tarefas do usuário - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Erro ao buscar tarefas'};
      }
    } catch (e) {
      print('🔴 Erro ao buscar tarefas: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // Buscar TODAS as tarefas (para dashboard de admin/dev)
  static Future<Map<String, dynamic>> getAllTasks() async {
    if (authToken == null) {
      return {'success': false, 'error': 'Token não encontrado'};
    }

    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/tasks'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      print('🟢 Buscando todas as tarefas - Status: ${response.statusCode}');
      print('📦 Resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Erro ao buscar tarefas'};
      }
    } catch (e) {
      print('🔴 Erro ao buscar tarefas: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // Atualizar status da tarefa - CORRIGIDO com a rota /status
  static Future<Map<String, dynamic>> updateTaskStatus({
    required int taskId,
    required String status,
  }) async {
    if (currentUserId == null) {
      return {'success': false, 'error': 'Usuário não logado'};
    }

    try {
      final headers = await _getHeaders();
      
      // URL CORRIGIDA: adiciona /status no final
      final response = await http.patch(
        Uri.parse('$baseUrl/api/tasks/$taskId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 10));

      print('🟢 Atualizando tarefa $taskId - Status: ${response.statusCode}');
      print('📦 Resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Erro ao atualizar tarefa'};
      }
    } catch (e) {
      print('🔴 Erro ao atualizar tarefa: $e');
      return {'success': false, 'error': 'Erro de conexão: $e'};
    }
  }

  // Método para verificar se o usuário está autenticado
  static bool isAuthenticated() {
    return authToken != null && currentUserId != null;
  }

  // Método para fazer logout
  static void logout() {
    authToken = null;
    currentUserId = null;
    currentUserRole = null;
    print('🔵 Usuário deslogado');
  }

  // Método para obter informações do usuário atual
  static Map<String, dynamic>? getCurrentUser() {
    if (currentUserId == null) return null;
    return {
      'id': currentUserId,
      'role': currentUserRole,
      'token': authToken,
    };
  }
}