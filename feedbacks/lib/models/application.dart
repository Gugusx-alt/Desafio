class Application {
  final int id;
  final String name;
  final String? description;
  final int? createdBy;
  final DateTime createdAt;
  List<Map<String, dynamic>> users; // Usuários vinculados

  Application({
    required this.id,
    required this.name,
    this.description,
    this.createdBy,
    required this.createdAt,
    this.users = const [],
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as int?,
      createdAt: DateTime.parse(json['created_at']),
      users: json['users'] != null 
          ? List<Map<String, dynamic>>.from(json['users'])
          : [],
    );
  }
}