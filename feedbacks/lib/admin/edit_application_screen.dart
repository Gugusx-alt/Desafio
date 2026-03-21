import 'package:flutter/material.dart';
import 'package:feedbacks/services/application_management_service.dart';
import 'package:feedbacks/models/application.dart';

class EditApplicationScreen extends StatefulWidget {
  final Application application;
  
  const EditApplicationScreen({super.key, required this.application});

  @override
  State<EditApplicationScreen> createState() => _EditApplicationScreenState();
}

class _EditApplicationScreenState extends State<EditApplicationScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.application.name);
    _descriptionController = TextEditingController(text: widget.application.description ?? '');
    _selectedStatus = widget.application.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('Nome é obrigatório', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApplicationManagementService.updateApplication(
      id: widget.application.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      status: _selectedStatus,
    );

    if (!mounted) return;

    if (result['success']) {
      _showMessage('Aplicação atualizada com sucesso!');
      Navigator.pop(context, true);
    } else {
      _showMessage(result['error'] ?? 'Erro ao atualizar', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Aplicação'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Nome da Aplicação *',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Descrição',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Status',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'ativo', child: Text('Ativa')),
                DropdownMenuItem(value: 'inativo', child: Text('Inativa')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedStatus = value);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
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