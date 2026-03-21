import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:feedbacks/models/task.dart';
import 'package:feedbacks/models/message.dart';
import 'package:feedbacks/services/message_service.dart';
import 'package:feedbacks/services/attachment_service.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  List<Message> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Busca mensagens
    final messages = await MessageService.getMessages(widget.task.id);
    
    // Busca anexos e converte em mensagens
    final attachments = await AttachmentService.getAttachments(widget.task.id);
    
    final attachmentMessages = attachments.map((att) {
      final imageUrl = '${ApiService.baseUrl}/uploads/${att.filePath.split('/').last}';
      return Message(
        id: att.id,
        taskId: widget.task.id,
        userId: att.uploadedBy,
        content: '',
        createdAt: att.createdAt,
        userName: att.uploadedByName,
        userRole: 'cliente',
        attachmentUrl: imageUrl,
        attachmentType: att.fileType,
        attachmentName: att.fileName,
      );
    }).toList();
    
    // Junta mensagens e anexos
    List<Message> allMessages = [...messages, ...attachmentMessages];
    allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    setState(() {
      _messages = allMessages;
      _isLoading = false;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    final result = await MessageService.sendMessage(widget.task.id, content);

    if (result['success']) {
      _messageController.clear();
      
      final newMessage = Message(
        id: result['data']['id'],
        taskId: widget.task.id,
        userId: ApiService.currentUserId!,
        content: content,
        createdAt: DateTime.now(),
        userName: ApiService.getCurrentUser()?['name'] ?? 'Você',
        userRole: ApiService.currentUserRole ?? 'cliente',
      );
      
      setState(() {
        _messages.add(newMessage);
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Erro'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isSending = false);
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'mp4', 'mov', 'txt', 'zip', 'rar'],
    );

    if (result != null) {
      final file = result.files.first;
      if (file.bytes != null) {
        await _uploadFileWeb(file.name, file.bytes!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao ler arquivo'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadFileWeb(String fileName, Uint8List bytes) async {
    setState(() => _isUploading = true);

    try {
      final headers = await ApiService.getHeaders();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/tasks/${widget.task.id}/attachments'),
      );
      
      request.headers.addAll(headers);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        
        final imageUrl = '${ApiService.baseUrl}/uploads/${data['data']['file_path'].split('/').last}';
        
        final fileMessage = Message(
          id: data['data']['id'],
          taskId: widget.task.id,
          userId: ApiService.currentUserId!,
          content: '',
          createdAt: DateTime.now(),
          userName: ApiService.getCurrentUser()?['name'] ?? 'Você',
          userRole: ApiService.currentUserRole ?? 'cliente',
          attachmentUrl: imageUrl,
          attachmentType: data['data']['file_type'],
          attachmentName: fileName,
        );
        
        setState(() {
          _messages.add(fileMessage);
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo enviado!'), backgroundColor: Colors.green),
        );
      } else {
        final data = jsonDecode(responseBody);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Erro'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isUploading = false);
  }

  Future<void> _deleteAttachment(Message msg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir'),
        content: Text('Excluir "${msg.attachmentName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await AttachmentService.deleteAttachment(msg.id);

    if (result['success']) {
      setState(() {
        _messages.removeWhere((m) => m.id == msg.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anexo removido'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      html.window.open(url, '_blank');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download de $fileName iniciado'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao baixar'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 7) return DateFormat('dd/MM/yyyy HH:mm').format(date);
    if (diff.inDays > 0) return '${diff.inDays}d atrás';
    if (diff.inHours > 0) return '${diff.inHours}h atrás';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min atrás';
    return 'agora';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'aberta': return 'Aberta';
      case 'em_andamento': return 'Em Andamento';
      case 'concluida': return 'Concluída';
      case 'cancelada': return 'Cancelada';
      default: return status;
    }
  }

  bool _isImage(String? type) {
    return type?.startsWith('image/') ?? false;
  }

  bool _isPdf(String? type) {
    return type == 'application/pdf';
  }

  bool _isVideo(String? type) {
    return type?.startsWith('video/') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.task, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.task.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text(
                              '${_getStatusText(widget.task.status)} • ${widget.task.categoryText}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // Chat
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text('Nenhuma mensagem', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg.userId == ApiService.currentUserId;
                            final hasAttachment = msg.attachmentUrl != null;
                            final isImage = _isImage(msg.attachmentType);
                            final isPdf = _isPdf(msg.attachmentType);
                            final isVideo = _isVideo(msg.attachmentType);
                            
                            return Align(
                              alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      msg.userName,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // Imagem
                                    if (hasAttachment && isImage)
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              child: InteractiveViewer(
                                                child: Image.network(msg.attachmentUrl!),
                                              ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            msg.attachmentUrl!,
                                            width: 200,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                width: 200,
                                                height: 200,
                                                color: Colors.grey.shade200,
                                                child: const Center(child: CircularProgressIndicator()),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 200,
                                                height: 200,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.broken_image, size: 50),
                                              );
                                            },
                                          ),
                                        ),
                                      )
                                    
                                    // Arquivo com botão de download e delete
                                    else if (hasAttachment)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(isPdf ? Icons.picture_as_pdf : (isVideo ? Icons.video_file : Icons.insert_drive_file)),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                msg.attachmentName ?? 'Arquivo',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _downloadFile(msg.attachmentUrl!, msg.attachmentName ?? 'arquivo'),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                child: const Icon(Icons.file_download, size: 18),
                                              ),
                                            ),
                                            if (isMe)
                                              GestureDetector(
                                                onTap: () => _deleteAttachment(msg),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  child: const Icon(Icons.close, size: 18, color: Colors.red),
                                                ),
                                              ),
                                          ],
                                        ),
                                      )
                                    
                                    // Texto normal
                                    else if (msg.content.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(msg.content),
                                      ),
                                    
                                    Text(
                                      _formatDate(msg.createdAt),
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // Input
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: _isUploading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.attach_file),
                        onPressed: _isUploading ? null : _pickAndUploadFile,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Mensagem...',
                            hintStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: _isSending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                        onPressed: _isSending ? null : _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}