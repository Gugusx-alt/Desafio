
import 'package:flutter/material.dart';
import '../models/task.dart';


class TaskCard extends StatelessWidget {
  // Dados da tarefa a ser exibida
  final Task task;
  // Role do usuário atual (admin, cliente, desenvolvedor)
  final String userRole;
  // Função chamada ao clicar no card (abrir detalhes)
  final VoidCallback? onTap;
  // Função chamada ao clicar no botão de alterar status
  final VoidCallback? onStatusChange;

  // Construtor do card
  const TaskCard({
    super.key,
    required this.task,
    required this.userRole,
    this.onTap,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Sombra do card
      elevation: 2,
      // Margem externa (laterais 16px, vertical 8px)
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Bordas arredondadas
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      // Torna o card clicável
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          // Espaçamento interno
          padding: const EdgeInsets.all(16),
          child: Column(
            // Alinha tudo à esquerda
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LINHA 1: Título e status
              Row(
                children: [
                  // Título (expande para ocupar espaço disponível)
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Container do status com ícone e texto
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      // Cor do status com opacity baixa 
                      color: task.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      // Borda com a cor do status 
                      border: Border.all(
                        color: task.statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ícone do status
                        Icon(
                          task.statusIcon,
                          size: 14,
                          color: task.statusColor,
                        ),
                        const SizedBox(width: 4),
                        // Texto do status
                        Text(
                          _getStatusText(task.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: task.statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // LINHA 2: Descrição (se existir)
              if (task.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,           // Limita a 2 linhas
                  overflow: TextOverflow.ellipsis, // Adiciona ... se passar
                ),
              ],
              
              const SizedBox(height: 12),
              
              //Informações do rodapé
              Row(
                children: [
                  // Ícone de aplicação
                  Icon(
                    Icons.apps,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  // Id da aplicação
                  Text(
                    'App #${task.applicationId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Ícone de pessoa
                  Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  // Id do criador
                  Text(
                    'Criador: #${task.createdBy}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(), // Empurra o próximo item para a direita
                  // Data formatada de criação
                  Text(
                    _formatDate(task.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              
              //Botão de alterar status (só para admin/dev)
              if (userRole != 'cliente' && onStatusChange != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: onStatusChange,
                      style: ElevatedButton.styleFrom(
                        // Cor do botão é a cor do status
                        backgroundColor: task.statusColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(100, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Alterar Status'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Converte o código do status para texto amigável
  String _getStatusText(String status) {
    switch (status) {
      case 'aberta':
        return 'Aberta';
      case 'em_andamento':
        return 'Em Andamento';
      case 'concluida':
        return 'Concluída';
      case 'cancelada':
        return 'Cancelada';
      default:
        return status;
    }
  }

  // Formata a data 
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // Mais de 7 dias: mostra data completa
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    // Entre 1 e 7 dias: mostra dias
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    // Entre 1 e 24 horas: mostra horas
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    // Entre 1 e 60 minutos: mostra minutos
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    // Menos de 1 minuto: mostra "agora"
    } else {
      return 'agora';
    }
  }
}