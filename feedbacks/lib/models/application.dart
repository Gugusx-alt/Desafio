class Application {
  final int id;
  final String name;
  final String? description;
  final int? createdBy;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? taskCount; // 🔥 NOVO: quantidade de tarefas vinculadas

  Application({
    required this.id,
    required this.name,
    this.description,
    this.createdBy,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.taskCount,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as int?,
      status: json['status'] as String? ?? 'ativo',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      taskCount: json['task_count'] != null 
          ? (json['task_count'] as num).toInt() 
          : null, // 🔥 NOVO
    );
  }
}