import 'package:flutter/material.dart';
import 'package:feedbacks/services/application_service.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/models/application.dart';

class LinkUserScreen extends StatefulWidget {
  final Application application;
  const LinkUserScreen({super.key, required this.application});

  @override
  State<LinkUserScreen> createState() => _LinkUserScreenState();
}

class _LinkUserScreenState extends State<LinkUserScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _selectedRole = 'cliente';
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    _users = await ApplicationService.getAllUsers();
    setState(() => _isLoading = false);
  }

  Future<void> _handleLink() async {
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um usuário')),
      );
      return;
    }

    final result = await ApplicationService.linkUserToApplication(
      applicationId: widget.application.id,
      userId: _selectedUserId!,
      roleInApp: _selectedRole!,
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Usuário vinculado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vincular Usuário - ${widget.application.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Selecione um usuário',
                      border: OutlineInputBorder(),
                    ),
                    items: _users.map((user) {
                      return DropdownMenuItem<int>(
                        value: user['id'],
                        child: Text('${user['name']} (${user['role']})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUserId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Função na aplicação',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'cliente',
                        child: Text('Cliente'),
                      ),
                      DropdownMenuItem(
                        value: 'desenvolvedor',
                        child: Text('Desenvolvedor'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handleLink,
                    child: const Text('Vincular Usuário'),
                  ),
                ],
              ),
            ),
    );
  }
}