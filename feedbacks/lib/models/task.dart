import 'package:flutter/material.dart';

class Task {
  final int id;
  final String title;
  final String? description;
  final String status;
  final String category; // bug, ajuste, melhoria
  final int applicationId;
  final int createdBy;
  final int? assignedTo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.category,
    required this.applicationId,
    required this.createdBy,
    this.assignedTo,
    required this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      category: json['category'] as String? ?? 'ajuste',
      applicationId: json['application_id'] as int,
      createdBy: json['created_by'] as int,
      assignedTo: json['assigned_to'] as int?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Cores baseadas no status
  Color get statusColor {
    switch (status) {
      case 'aberta':
        return Colors.blue;
      case 'em_andamento':
        return Colors.orange;
      case 'concluida':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Ícone baseado no status
  IconData get statusIcon {
    switch (status) {
      case 'aberta':
        return Icons.pending_actions;
      case 'em_andamento':
        return Icons.play_circle;
      case 'concluida':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Ícone baseado na categoria
  IconData get categoryIcon {
    switch (category) {
      case 'bug':
        return Icons.bug_report;
      case 'ajuste':
        return Icons.tune;
      case 'melhoria':
        return Icons.trending_up;
      default:
        return Icons.help;
    }
  }

  // Texto da categoria
  String get categoryText {
    switch (category) {
      case 'bug':
        return 'Bug';
      case 'ajuste':
        return 'Ajuste';
      case 'melhoria':
        return 'Melhoria';
      default:
        return category;
    }
  }

  // Cor da categoria
  Color get categoryColor {
    switch (category) {
      case 'bug':
        return Colors.red;
      case 'ajuste':
        return Colors.orange;
      case 'melhoria':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}