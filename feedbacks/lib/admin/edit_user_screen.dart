import 'package:flutter/material.dart';
import 'package:feedbacks/services/user_management_service.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  
  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late String _selectedRole;
  late String _selectedStatus;
  
  bool _isLoading = false;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _emailController = TextEditingController(text: widget.user['email']);
    _phoneController = TextEditingController(text: widget.user['phone'] ?? '');
    _passwordController = TextEditingController();
    _selectedRole = widget.user['role'];
    _selectedStatus = widget.user['status'] ?? 'ativo';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    final Map<String, dynamic> data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'role': _selectedRole,
      'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
      'status': _selectedStatus,
    };

    if (_changePassword && _passwordController.text.isNotEmpty) {
      data['password'] = _passwordController.text;
    }

    final result = await UserManagementService.updateUser(
      userId: widget.user['id'],
      name: data['name'],
      email: data['email'],
      role: data['role'],
      phone: data['phone'],
      status: data['status'],
      password: _changePassword ? data['password'] : null,
    );

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Usuário atualizado com sucesso!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${result['error']}'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Usuário'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                border: OutlineInputBorder(),
                hintText: '(11) 99999-9999',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Cargo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                DropdownMenuItem(value: 'desenvolvedor', child: Text('Desenvolvedor')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ativo', child: Text('Ativo')),
                DropdownMenuItem(value: 'inativo', child: Text('Inativo')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedStatus = value);
                }
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Alterar senha'),
              value: _changePassword,
              onChanged: (value) {
                setState(() => _changePassword = value ?? false);
              },
            ),
            if (_changePassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  border: OutlineInputBorder(),
                  hintText: 'Deixe em branco para manter a atual',
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Salvar Alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}