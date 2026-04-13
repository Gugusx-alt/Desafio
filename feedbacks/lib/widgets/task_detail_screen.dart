import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:feedbacks/pallet.dart';
import 'package:feedbacks/models/task.dart';
import 'package:feedbacks/models/message.dart';
import 'package:feedbacks/services/message_service.dart';
import 'package:feedbacks/services/attachment_service.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:feedbacks/services/socket_service.dart';
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
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _connectSocket();
  }

  @override
  void dispose() {
    SocketService.offNewMessage();
    SocketService.leaveTask(widget.task.id);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ─── Socket ───────────────────────────────────────────────────────

  void _connectSocket() {
    if (!SocketService.isConnected) SocketService.connect();
    SocketService.joinTask(widget.task.id);
    SocketService.onNewMessage(_onSocketMessage);
  }

  void _onSocketMessage(Map<String, dynamic> data) {
    // Ignora se a mensagem já existe (enviada por mim via REST)
    final id = data['id'] is int
        ? data['id'] as int
        : int.tryParse(data['id'].toString()) ?? 0;
    if (_messages.any((m) => m.id == id)) return;

    final msg = Message(
      id: id,
      taskId: widget.task.id,
      userId: data['user_id'] is int
          ? data['user_id'] as int
          : int.tryParse(data['user_id'].toString()) ?? 0,
      content: data['content'] as String? ?? '',
      createdAt: data['created_at'] is String
          ? DateTime.tryParse(data['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      userName: data['user_name'] as String? ?? 'Usuário',
      userRole: data['user_role'] as String? ?? 'cliente',
    );

    if (mounted) {
      setState(() => _messages.add(msg));
      _scrollToBottom();
    }
  }

  // ─── Dados ────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final messages = await MessageService.getMessages(widget.task.id);
    final attachments =
        await AttachmentService.getAttachments(widget.task.id);

    final attMessages = attachments.map((att) {
      final url =
          '${ApiService.baseUrl}/uploads/${att.filePath.split('/').last}';
      return Message(
        id: att.id,
        taskId: widget.task.id,
        userId: att.uploadedBy,
        content: '',
        createdAt: att.createdAt,
        userName: att.uploadedByName,
        userRole: 'cliente',
        attachmentUrl: url,
        attachmentType: att.fileType,
        attachmentName: att.fileName,
      );
    }).toList();

    final all = [...messages, ...attMessages]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (mounted) {
      setState(() {
        _messages = all;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // ─── Envio de mensagem ────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final content = _msgCtrl.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    final result =
        await MessageService.sendMessage(widget.task.id, content);

    if (result['success']) {
      _msgCtrl.clear();
      final newMsg = Message(
        id: result['data']['id'] is int
            ? result['data']['id'] as int
            : int.tryParse(result['data']['id'].toString()) ?? 0,
        taskId: widget.task.id,
        userId: ApiService.currentUserId!,
        content: content,
        createdAt: DateTime.now(),
        userName:
            ApiService.getCurrentUser()?['name'] as String? ?? 'Você',
        userRole: ApiService.currentUserRole ?? 'cliente',
      );
      setState(() => _messages.add(newMsg));
      _scrollToBottom();
    } else {
      _snack(result['error'] ?? 'Erro ao enviar', error: true);
    }
    setState(() => _isSending = false);
  }

  // ─── Upload de arquivo ────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: [
        'jpg', 'jpeg', 'png', 'gif', 'pdf', 'mp4', 'mov', 'txt', 'zip', 'rar'
      ],
    );
    if (result != null && result.files.first.bytes != null) {
      await _uploadFile(result.files.first.name,
          result.files.first.bytes!);
    }
  }

  Future<void> _uploadFile(String name, Uint8List bytes) async {
    setState(() => _isUploading = true);
    try {
      final headers = await ApiService.getHeaders();
      final req = http.MultipartRequest(
        'POST',
        Uri.parse(
            '${ApiService.baseUrl}/api/tasks/${widget.task.id}/attachments'),
      )
        ..headers.addAll(headers)
        ..files.add(http.MultipartFile.fromBytes('file', bytes,
            filename: name));

      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      if (resp.statusCode == 201) {
        final data = jsonDecode(body)['data'] as Map<String, dynamic>;
        final url =
            '${ApiService.baseUrl}/uploads/${(data['file_path'] as String).split('/').last}';
        final fileMsg = Message(
          id: data['id'] is int
              ? data['id'] as int
              : int.tryParse(data['id'].toString()) ?? 0,
          taskId: widget.task.id,
          userId: ApiService.currentUserId!,
          content: '',
          createdAt: DateTime.now(),
          userName:
              ApiService.getCurrentUser()?['name'] as String? ?? 'Você',
          userRole: ApiService.currentUserRole ?? 'cliente',
          attachmentUrl: url,
          attachmentType: data['file_type'] as String?,
          attachmentName: name,
        );
        setState(() => _messages.add(fileMsg));
        _scrollToBottom();
        _snack('Arquivo enviado!');
      } else {
        final err = jsonDecode(body);
        _snack(err['error'] ?? 'Erro no upload', error: true);
      }
    } catch (e) {
      _snack('Erro: $e', error: true);
    }
    setState(() => _isUploading = false);
  }

  // ─── Deletar anexo ────────────────────────────────────────────────

  Future<void> _deleteAttachment(Message msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderColor),
        ),
        title: const Text('Excluir anexo',
            style: TextStyle(color: textPrimary, fontSize: 16)),
        content: Text('Excluir "${msg.attachmentName}"?',
            style: const TextStyle(color: textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: statusCancelled),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final result =
        await AttachmentService.deleteAttachment(msg.id);
    if (result['success']) {
      setState(() =>
          _messages.removeWhere((m) => m.id == msg.id));
      _snack('Anexo removido');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? statusCancelled : statusDone,
    ));
  }

  String _fmtTime(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 7) return DateFormat('dd/MM HH:mm').format(d);
    if (diff.inDays > 0) return '${diff.inDays}d atrás';
    if (diff.inHours > 0) return '${diff.inHours}h atrás';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min atrás';
    return 'agora';
  }

  String _statusText(String s) {
    const map = {
      'aberta': 'Aberta',
      'em_andamento': 'Em Andamento',
      'concluida': 'Concluída',
      'cancelada': 'Cancelada',
    };
    return map[s] ?? s;
  }

  Color _statusColor(String s) {
    const map = {
      'aberta': statusOpen,
      'em_andamento': statusProgress,
      'concluida': statusDone,
      'cancelada': statusCancelled,
    };
    return map[s] ?? textMuted;
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.title,
              style: const TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _statusColor(widget.task.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${_statusText(widget.task.status)} · ${widget.task.categoryText}',
                  style: const TextStyle(
                      color: textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                const Divider(height: 1, color: borderColor),
                Expanded(child: _buildMessages()),
                _buildInput(),
              ],
            ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                color: textMuted, size: 40),
            SizedBox(height: 12),
            Text('Nenhuma mensagem ainda',
                style: TextStyle(color: textSecondary, fontSize: 14)),
            SizedBox(height: 4),
            Text('Inicie a conversa abaixo',
                style: TextStyle(color: textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _MessageBubble(
        msg: _messages[i],
        isMe: _messages[i].userId == ApiService.currentUserId,
        timeText: _fmtTime(_messages[i].createdAt),
        onDelete: _messages[i].attachmentUrl != null
            ? () => _deleteAttachment(_messages[i])
            : null,
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Botão de anexo
          _CircleBtn(
            icon: _isUploading
                ? null
                : Icons.attach_file_rounded,
            isLoading: _isUploading,
            color: textSecondary,
            onTap: _isUploading ? null : _pickFile,
          ),
          const SizedBox(width: 8),
          // Campo de texto
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              style: const TextStyle(color: textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Mensagem...',
                hintStyle:
                    const TextStyle(color: textMuted, fontSize: 14),
                filled: true,
                fillColor: surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                      color: primaryColor, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          // Botão enviar
          _CircleBtn(
            icon: Icons.send_rounded,
            isLoading: _isSending,
            color: primaryColor,
            filled: true,
            onTap: _isSending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ─── Balão de mensagem ────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final Message msg;
  final bool isMe;
  final String timeText;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.timeText,
    this.onDelete,
  });

  Color get _roleColor {
    switch (msg.userRole) {
      case 'admin':
        return secondaryColor;
      case 'desenvolvedor':
        return accentColor;
      default:
        return primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAtt = msg.attachmentUrl != null;
    final isImg = msg.attachmentType?.startsWith('image/') ?? false;
    final isPdf = msg.attachmentType == 'application/pdf';
    final isVideo = msg.attachmentType?.startsWith('video/') ?? false;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.70,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Nome + papel
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe) ...[
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _roleColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        msg.userName.isNotEmpty
                            ? msg.userName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: _roleColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    isMe ? 'Você' : msg.userName,
                    style: TextStyle(
                        color: _roleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Corpo da mensagem
            if (hasAtt && isImg)
              _ImageBubble(url: msg.attachmentUrl!, isMe: isMe)
            else if (hasAtt)
              _FileBubble(
                msg: msg,
                isMe: isMe,
                isPdf: isPdf,
                isVideo: isVideo,
                onDelete: onDelete,
              )
            else if (msg.content.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? primaryColor : surfaceElevated,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Text(
                  msg.content,
                  style: TextStyle(
                      color: isMe ? Colors.white : textPrimary,
                      fontSize: 14,
                      height: 1.4),
                ),
              ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(
                timeText,
                style:
                    const TextStyle(color: textMuted, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final String url;
  final bool isMe;
  const _ImageBubble({required this.url, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: InteractiveViewer(
            child: Image.network(url),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        child: Image.network(
          url,
          width: 220,
          height: 180,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 220,
              height: 180,
              color: surfaceElevated,
              child: const Center(
                  child: CircularProgressIndicator(
                      color: primaryColor, strokeWidth: 2)),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            width: 220,
            height: 180,
            color: surfaceElevated,
            child: const Icon(Icons.broken_image_rounded,
                color: textMuted, size: 40),
          ),
        ),
      ),
    );
  }
}

class _FileBubble extends StatelessWidget {
  final Message msg;
  final bool isMe;
  final bool isPdf;
  final bool isVideo;
  final VoidCallback? onDelete;

  const _FileBubble({
    required this.msg,
    required this.isMe,
    required this.isPdf,
    required this.isVideo,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? primaryColor.withOpacity(0.15) : surfaceElevated,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: Border.all(
            color: isMe
                ? primaryColor.withOpacity(0.3)
                : borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPdf
                ? Icons.picture_as_pdf_rounded
                : isVideo
                    ? Icons.video_file_rounded
                    : Icons.insert_drive_file_rounded,
            color: isMe ? primaryColor : textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              msg.attachmentName ?? 'Arquivo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: isMe ? primaryColor : textPrimary,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => html.window.open(msg.attachmentUrl!, '_blank'),
            child: const Icon(Icons.file_download_rounded,
                size: 18, color: textSecondary),
          ),
          if (isMe && onDelete != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onDelete,
              child: const Icon(Icons.close_rounded,
                  size: 16, color: statusCancelled),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Botão circular (input actions) ──────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData? icon;
  final bool isLoading;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  const _CircleBtn({
    required this.icon,
    required this.isLoading,
    required this.color,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: filled ? Colors.white : color),
              )
            : Icon(icon,
                size: 18,
                color: filled ? Colors.white : color),
      ),
    );
  }
}
