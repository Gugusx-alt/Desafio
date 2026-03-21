import 'package:flutter/material.dart';

class Attachment {
  final int id;
  final int taskId;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final int uploadedBy;
  final String uploadedByName;
  final DateTime createdAt;

  Attachment({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.createdAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as int,
      taskId: json['task_id'] as int,
      fileName: json['file_name'] as String? ?? 'Arquivo', // 🔥 FALLBACK
      filePath: json['file_path'] as String? ?? '',
      fileType: json['file_type'] as String? ?? 'application/octet-stream',
      fileSize: json['file_size'] as int? ?? 0,
      uploadedBy: json['uploaded_by'] as int? ?? 0,
      uploadedByName: json['uploaded_by_name'] as String? ?? 'Usuário',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData get fileIcon {
    if (fileType.startsWith('image/')) return Icons.image;
    if (fileType == 'application/pdf') return Icons.picture_as_pdf;
    if (fileType.startsWith('video/')) return Icons.video_file;
    return Icons.insert_drive_file;
  }
}