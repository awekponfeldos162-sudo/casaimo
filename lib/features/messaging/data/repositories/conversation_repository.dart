import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ConversationRepository {
  final _col = FirebaseFirestore.instance.collection('messages');

  Stream<List<ConversationModel>> watchByUser(String userId) {
    return _col
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ConversationModel.fromFirestore).toList());
  }

  Stream<ConversationModel?> watchById(String id) {
    return _col
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? ConversationModel.fromFirestore(doc) : null);
  }

  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _col
        .doc(conversationId)
        .collection('msgs')
        .orderBy('sentAt')
        .snapshots()
        .map((s) => s.docs.map(MessageModel.fromFirestore).toList());
  }

  Future<String> createOrGet(String guestId, String hostId, String listingId, String listingTitle, {
    String hostName = '',
    String hostPhone = '',
    String hostAvatar = '',
  }) async {
    final existing = await _col
        .where('participants', arrayContains: guestId)
        .where('listingId', isEqualTo: listingId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final ref = await _col.add({
      'participants': [guestId, hostId],
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'listingId': listingId,
      'listingTitle': listingTitle,
      'unreadCount': {guestId: 0, hostId: 0},
      'hostId': hostId,
      'hostName': hostName,
      'hostPhone': hostPhone,
      'hostAvatar': hostAvatar,
    });
    return ref.id;
  }

  Future<void> sendMessage(String conversationId, MessageModel msg, String senderId) async {
    await _col.doc(conversationId).collection('msgs').add(msg.toFirestore());
    await _col.doc(conversationId).update({
      'lastMessage': msg.text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount.$senderId': 0,
    });
  }

  Future<void> markRead(String conversationId, String userId) async {
    await _col.doc(conversationId).update({'unreadCount.$userId': 0});
  }
}
