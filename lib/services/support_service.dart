import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/support_message.dart';
import '../models/support_ticket.dart';

/// Servicio para gestionar el chat de soporte técnico en Firestore.
///
/// Estructura en Firestore:
///   support_chats/{userId}/messages/{messageId}
///
/// Cada documento de chat raíz (`support_chats/{userId}`) almacena metadatos
/// como el último mensaje, fecha y estado del ticket.
class SupportService {
  static final _auth = fb.FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static String? get _userId => _auth.currentUser?.uid;

  /// Referencia a la colección de mensajes del usuario actual.
  static CollectionReference<Map<String, dynamic>>? get _messagesRef {
    if (_userId == null) return null;
    return _firestore
        .collection('support_chats')
        .doc(_userId!)
        .collection('messages');
  }

  /// Stream en tiempo real de los mensajes ordenados cronológicamente.
  static Stream<List<SupportMessage>> getMessagesStream() {
    final ref = _messagesRef;
    if (ref == null) return Stream.value([]);

    return ref.orderBy('timestamp', descending: false).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => SupportMessage.fromFirestore(doc))
              .toList(),
        );
  }

  /// Envía un mensaje del usuario y actualiza el ticket de forma atómica.
  static Future<void> sendMessage(String text, {String? senderName}) async {
    final userId = _userId;
    final messagesRef = _messagesRef;
    if (userId == null || messagesRef == null) {
      throw StateError('Debes iniciar sesión para contactar a soporte.');
    }

    final chatRef = _firestore.collection('support_chats').doc(userId);
    final messageRef = messagesRef.doc();
    final now = Timestamp.now();

    await _firestore.runTransaction((transaction) async {
      final chat = await transaction.get(chatRef);
      transaction.set(
        messageRef,
        SupportMessage(
          id: messageRef.id,
          text: text,
          sender: MessageSender.user,
          timestamp: now.toDate(),
          senderName: senderName,
        ).toFirestore(),
      );
      transaction.set(chatRef, {
        'userId': userId,
        'userName': senderName ?? 'Usuario',
        'lastMessage': text,
        'lastMessageAt': now,
        'status': 'open',
        'updatedAt': now,
        'unreadBySupport': FieldValue.increment(1),
        'unreadByUser': 0,
        if (!chat.exists) 'createdAt': now,
      }, SetOptions(merge: true));
    });
  }

  /// Obtiene todos los tickets para la bandeja de administradores.
  static Stream<List<SupportTicket>> getTicketsStream() {
    return _firestore
        .collection('support_chats')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(SupportTicket.fromFirestore)
            .toList());
  }

  /// Obtiene los mensajes de un ticket desde la bandeja administrativa.
  static Stream<List<SupportMessage>> getTicketMessagesStream(String userId) {
    return _firestore
        .collection('support_chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(SupportMessage.fromFirestore)
            .toList());
  }

  /// Envía una respuesta como personal de soporte.
  static Future<void> sendSupportMessage(
    String userId,
    String text, {
    required String supportName,
  }) async {
    final chatRef = _firestore.collection('support_chats').doc(userId);
    final messageRef = chatRef.collection('messages').doc();
    final now = Timestamp.now();
    final batch = _firestore.batch();

    batch.set(
      messageRef,
      SupportMessage(
        id: messageRef.id,
        text: text,
        sender: MessageSender.support,
        timestamp: now.toDate(),
        senderName: supportName,
      ).toFirestore(),
    );
    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageAt': now,
      'status': 'inProgress',
      'updatedAt': now,
      'unreadBySupport': 0,
      'unreadByUser': FieldValue.increment(1),
    });
    await batch.commit();
  }

  static Future<void> markTicketReadBySupport(String userId) {
    return _firestore.collection('support_chats').doc(userId).update({
      'unreadBySupport': 0,
    });
  }

  static Future<void> updateTicketStatus(String userId, String status) {
    return _firestore.collection('support_chats').doc(userId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }
}
