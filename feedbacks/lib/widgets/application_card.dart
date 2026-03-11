import 'package:flutter/material.dart';
import 'package:feedbacks/models/application.dart';

class ApplicationCard extends StatelessWidget {
  final Application application;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ApplicationCard({
    super.key,
    required this.application,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade100,
          child: Icon(
            Icons.apps,
            color: Colors.deepPurple.shade700,
          ),
        ),
        title: Text(
          application.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(application.description ?? 'Sem descrição'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}