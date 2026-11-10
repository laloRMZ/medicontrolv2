import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/support_message.dart';
import '../../models/support_ticket.dart';
import '../../providers/auth_provider.dart';
import '../../services/alert_service.dart';
import '../../services/support_service.dart';

class SupportInboxScreen extends StatelessWidget {
  const SupportInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.read<AuthProvider>().isAdmin) {
      return const Scaffold(
        body: Center(child: Text('No tienes acceso a los tickets de soporte.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Soporte técnico')),
      body: StreamBuilder<List<SupportTicket>>(
        stream: SupportService.getTicketsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar los tickets de soporte.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tickets = snapshot.data!;
          if (tickets.isEmpty) {
            return const Center(
              child: Text('No hay conversaciones de soporte activas.'),
            );
          }

          return ListView.separated(
            itemCount: tickets.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(ticket.userName.characters.first.toUpperCase()),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(ticket.userName)),
                    _StatusChip(status: ticket.status),
                  ],
                ),
                subtitle: Text(
                  ticket.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: ticket.unreadBySupport > 0
                    ? Badge(label: Text('${ticket.unreadBySupport}'))
                    : null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SupportTicketChatScreen(ticket: ticket),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class SupportTicketChatScreen extends StatefulWidget {
  final SupportTicket ticket;

  const SupportTicketChatScreen({super.key, required this.ticket});

  @override
  State<SupportTicketChatScreen> createState() =>
      _SupportTicketChatScreenState();
}

class _SupportTicketChatScreenState extends State<SupportTicketChatScreen> {
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    SupportService.markTicketReadBySupport(widget.ticket.userId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await SupportService.sendSupportMessage(
        widget.ticket.userId,
        text,
        supportName: context.read<AuthProvider>().currentUser!.fullName,
      );
      _messageController.clear();
    } catch (_) {
      if (mounted) {
        AlertService.showError(
          context,
          title: 'Error',
          message: 'No se pudo enviar la respuesta. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _changeStatus(String status) async {
    try {
      await SupportService.updateTicketStatus(widget.ticket.userId, status);
    } catch (_) {
      if (mounted) {
        AlertService.showError(
          context,
          title: 'Error',
          message: 'No se pudo actualizar el estado del ticket.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ticket.userName),
            Text(
              _statusLabel(widget.ticket.status),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Cambiar estado',
            onSelected: _changeStatus,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'open', child: Text('Abierto')),
              PopupMenuItem(value: 'inProgress', child: Text('En progreso')),
              PopupMenuItem(value: 'resolved', child: Text('Resuelto')),
              PopupMenuItem(value: 'closed', child: Text('Cerrado')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<SupportMessage>>(
              stream: SupportService.getTicketMessagesStream(
                widget.ticket.userId,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('No se pudieron cargar los mensajes.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final sentBySupport =
                        message.sender == MessageSender.support;
                    return Align(
                      alignment: sentBySupport
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * .75,
                        ),
                        decoration: BoxDecoration(
                          color: sentBySupport
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: sentBySupport ? Colors.white : null,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Responder al usuario...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_statusLabel(status)),
      visualDensity: VisualDensity.compact,
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'inProgress':
      return 'En progreso';
    case 'resolved':
      return 'Resuelto';
    case 'closed':
      return 'Cerrado';
    default:
      return 'Abierto';
  }
}
