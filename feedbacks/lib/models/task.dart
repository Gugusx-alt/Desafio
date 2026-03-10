// Importa o pacote de material design do Flutter (para usar Colors e Icons)
import 'package:flutter/material.dart';

// Classe modelo que representa uma tarefa no sistema
class Task {
  // Propriedades da tarefa (correspondem às colunas da tabela tasks)
  final int id;                  // ID único da tarefa
  final String title;             // Título da tarefa
  final String? description;      // Descrição (opcional)
  final String status;            // Status: aberta, em_andamento, concluida, cancelada
  final int applicationId;        // ID da aplicação relacionada
  final int createdBy;            // ID do usuário que criou
  final int? assignedTo;          // ID do usuário atribuído (opcional)
  final DateTime createdAt;       // Data de criação
  final DateTime? updatedAt;      // Data da última atualização (opcional)

  // Construtor da classe
  Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.applicationId,
    required this.createdBy,
    this.assignedTo,
    required this.createdAt,
    this.updatedAt,
  });

  // Converte um JSON (do backend) em um objeto Task
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      applicationId: json['application_id'] as int,
      createdBy: json['created_by'] as int,
      assignedTo: json['assigned_to'] as int?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Retorna uma cor diferente para cada status (usado nos cards)
  Color get statusColor {
    switch (status) {
      case 'aberta':
        return Colors.blue;        // Azul para tarefas abertas
      case 'em_andamento':
        return Colors.orange;      // Laranja para em andamento
      case 'concluida':
        return Colors.green;       // Verde para concluídas
      case 'cancelada':
        return Colors.red;         // Vermelho para canceladas
      default:
        return Colors.grey;        // Cinza para status desconhecido
    }
  }

  // Retorna um ícone diferente para cada status (usado nos cards)
  IconData get statusIcon {
    switch (status) {
      case 'aberta':
        return Icons.pending_actions;    // Ícone de pendente
      case 'em_andamento':
        return Icons.play_circle;        // Ícone de play
      case 'concluida':
        return Icons.check_circle;       // Ícone de check
      case 'cancelada':
        return Icons.cancel;              // Ícone de cancelado
      default:
        return Icons.help;                // Ícone de ajuda para desconhecido
    }
  }
}