import 'package:flutter/material.dart';
import 'package:feedbacks/services/api_service.dart';

class Message {
  final int id;
  final int taskId;
  final int userId;
  final String content;
  final DateTime createdAt;
  final String userName;
  final String userRole;
  final String? attachmentUrl;  // 🔥 URL da imagem/arquivo
  final String? attachmentType; // 🔥 Tipo do arquivo (image/png, application/pdf, etc)
  final String? attachmentName; // 🔥 Nome original do arquivo

  Message({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.userName,
    required this.userRole,
    this.attachmentUrl,
    this.attachmentType,
    this.attachmentName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      taskId: json['task_id'] as int,
      userId: json['user_id'] as int,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'] as String,
      userRole: json['user_role'] as String,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentType: json['attachment_type'] as String?,
      attachmentName: json['attachment_name'] as String?,
    );
  }

  bool get isFromCurrentUser => userId == ApiService.currentUserId;

  Color get roleColor {
    switch (userRole) {
      case 'admin': return Colors.purple;
      case 'cliente': return Colors.blue;
      case 'desenvolvedor': return Colors.green;
      default: return Colors.grey;
    }
  }
  
  // 🔥 Verifica se é uma imagem
  bool get isImage => attachmentType?.startsWith('image/') ?? false;
  
  // 🔥 Verifica se é PDF
  bool get isPdf => attachmentType == 'application/pdf';
  
  // 🔥 Verifica se é vídeo
  bool get isVideo => attachmentType?.startsWith('video/') ?? false;
  
  // 🔥 Verifica se tem anexo
  bool get hasAttachment => attachmentUrl != null;
}