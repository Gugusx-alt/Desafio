import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:feedbacks/services/api_service.dart';

/// Serviço singleton de WebSocket via Socket.io.
/// Conectar após login; desconectar no logout.
class SocketService {
  static IO.Socket? _socket;

  static bool get isConnected => _socket?.connected ?? false;

  // ─── Ciclo de vida ────────────────────────────────────────────────

  static void connect() {
    final token = ApiService.authToken;
    if (token == null) return;

    _socket = IO.io(
      ApiService.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) => print('🔌 Socket conectado'))
      ..onDisconnect((_) => print('❌ Socket desconectado'))
      ..onConnectError((e) => print('⚠️ Erro de conexão: $e'))
      ..connect();
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  // ─── Salas de tarefa ──────────────────────────────────────────────

  static void joinTask(int taskId) {
    _socket?.emit('join_task', taskId);
  }

  static void leaveTask(int taskId) {
    _socket?.emit('leave_task', taskId);
  }

  // ─── Eventos de mensagem ──────────────────────────────────────────

  static void onNewMessage(void Function(Map<String, dynamic>) callback) {
    _socket?.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      } else if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  static void offNewMessage() {
    _socket?.off('new_message');
  }
}
