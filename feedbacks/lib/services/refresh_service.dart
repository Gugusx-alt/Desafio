import 'dart:async';

/// Serviço para gerenciar atualizações em tempo real entre telas
/// Usa StreamController para permitir comunicação reativa
class RefreshService {
  // Singleton: garante apenas uma instância em toda a aplicação
  static final RefreshService _instance = RefreshService._internal();
  factory RefreshService() => _instance;
  RefreshService._internal();

  // StreamController para controlar as atualizações
  // broadcast() permite múltiplos ouvintes
  final _refreshController = StreamController<bool>.broadcast();

  // Getter para o stream (os widgets ouvem isso)
  Stream<bool> get refreshStream => _refreshController.stream;

  // Método para disparar a atualização do dashboard
  void refreshDashboard() {
    print('🔄 Disparando atualização do dashboard');
    _refreshController.add(true);
  }

  // Libera recursos quando não for mais necessário
  void dispose() {
    _refreshController.close();
  }
}