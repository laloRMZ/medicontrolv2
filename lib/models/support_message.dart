import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageSender { user, support }

class SupportMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final String? senderName;

  const SupportMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.senderName,
  });

  factory SupportMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportMessage(
      id: doc.id,
      text: data['text'] ?? '',
      sender: data['sender'] == 'support'
          ? MessageSender.support
          : MessageSender.user,
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderName: data['senderName'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'text': text,
        'sender': sender == MessageSender.support ? 'support' : 'user',
        'timestamp': Timestamp.fromDate(timestamp),
        'senderName': senderName,
      };
}

