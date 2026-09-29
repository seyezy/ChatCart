import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_models.dart';

class ChatRepository {
  final FirebaseFirestore db;

  ChatRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;

  String directConversationId(String a, String b) {
    final ids = [a, b]..sort();
    return 'direct_${ids[0]}_${ids[1]}';
  }

  Future<String> ensureDirectConversation(String a, String b) async {
    if (a == b) {
      throw ArgumentError('A direct conversation requires two different users.');
    }
    final id = directConversationId(a, b);
    final ref = db.collection('conversations').doc(id);
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) return;
      transaction.set(ref, {
        'participants': [a, b],
        'type': 'direct',
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastSenderId': null,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    return id;
  }

  Stream<List<ChatConversation>> watchConversations(String uid) => db
      .collection('conversations')
      .where('participants', arrayContains: uid)
      .orderBy('updatedAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(ChatConversation.fromDoc).toList());

  Stream<List<ChatMessage>> watchMessages(String conversationId) => db
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(ChatMessage.fromDoc).toList());

  Stream<DateTime?> watchLastReadAt({
    required String conversationId,
    required String uid,
  }) => db
      .collection('conversations')
      .doc(conversationId)
      .collection('reads')
      .doc(uid)
      .snapshots()
      .map((snapshot) {
        final value = snapshot.data()?['lastReadAt'];
        return value is Timestamp ? value.toDate() : null;
      });

  Future<void> sendText({
    required String conversationId,
    required String senderId,
    required String text,
    String? productId,
  }) =>
      _send(
        conversationId: conversationId,
        senderId: senderId,
        type: productId == null ? 'text' : 'product',
        text: text,
        productId: productId,
      );

  Future<void> sendImage({
    required String conversationId,
    required String senderId,
    required String imageUrl,
    String text = '',
  }) =>
      _send(
        conversationId: conversationId,
        senderId: senderId,
        type: 'image',
        text: text,
        mediaUrl: imageUrl,
      );

  Future<void> _send({
    required String conversationId,
    required String senderId,
    required String type,
    required String text,
    String? mediaUrl,
    String? productId,
  }) async {
    final conversation = db.collection('conversations').doc(conversationId);
    final message = conversation.collection('messages').doc();
    final batch = db.batch();
    batch.set(message, {
      'id': message.id,
      'senderId': senderId,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [senderId],
    });
    batch.set(conversation, {
      'lastMessage': type == 'image' ? '📷 Photo' : text,
      'lastMessageType': type,
      'lastSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> markConversationRead({
    required String conversationId,
    required String uid,
  }) async {
    final query = await db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(350)
        .get();
    final batch = db.batch();
    var operations = 0;
    for (final doc in query.docs) {
      final data = doc.data();
      if (data['senderId'] == uid) continue;
      final readBy = List<String>.from(data['readBy'] ?? const []);
      if (!readBy.contains(uid)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([uid]),
        });
        operations++;
      }
    }
    batch.set(
      db
          .collection('conversations')
          .doc(conversationId)
          .collection('reads')
          .doc(uid),
      {'lastReadAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    operations++;
    if (operations > 0) await batch.commit();
  }

  Future<ChatUser?> getUser(String uid) async {
    final doc = await db.collection('users').doc(uid).get();
    return doc.exists ? ChatUser.fromDoc(doc) : null;
  }

  Stream<ChatUser?> watchUser(String uid) => db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? ChatUser.fromDoc(doc) : null);

  Stream<List<ChatUser>> watchUsers({required String exceptUid}) => db
      .collection('users')
      .limit(100)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .where((doc) => doc.id != exceptUid)
            .map(ChatUser.fromDoc)
            .toList(),
      );
}
