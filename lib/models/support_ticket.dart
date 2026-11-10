import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicket {
  final String userId;
  final String userName;
  final String lastMessage;
  final DateTime updatedAt;
  final String status;
  final int unreadBySupport;
  final int unreadByUser;

  const SupportTicket({
    required this.userId,
    required this.userName,
    required this.lastMessage,
    required this.updatedAt,
    required this.status,
    required this.unreadBySupport,
    required this.unreadByUser,
  });

  factory SupportTicket.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    return SupportTicket(
      userId: data['userId'] as String? ?? document.id,
      userName: data['userName'] as String? ?? 'Usuario',
      lastMessage: data['lastMessage'] as String? ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'open',
      unreadBySupport: data['unreadBySupport'] as int? ?? 0,
      unreadByUser: data['unreadByUser'] as int? ?? 0,
    );
  }
}
