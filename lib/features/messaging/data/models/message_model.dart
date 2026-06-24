import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String listingId;
  final String listingTitle;
  final Map<String, int> unreadCount;
  // Host contact info — stored when conversation is created from host profile
  final String hostId;
  final String hostName;
  final String hostPhone;
  final String hostAvatar;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.listingId,
    required this.listingTitle,
    required this.unreadCount,
    this.hostId = '',
    this.hostName = '',
    this.hostPhone = '',
    this.hostAvatar = '',
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(d['participants'] ?? []),
      lastMessage: d['lastMessage'] ?? '',
      lastMessageAt:
          (d['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      listingId: d['listingId'] ?? '',
      listingTitle: d['listingTitle'] ?? '',
      unreadCount: Map<String, int>.from(d['unreadCount'] ?? {}),
      hostId: d['hostId'] ?? '',
      hostName: d['hostName'] ?? '',
      hostPhone: d['hostPhone'] ?? '',
      hostAvatar: d['hostAvatar'] ?? '',
    );
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime sentAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.sentAt,
    required this.isRead,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      imageUrl: d['imageUrl'],
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: d['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'text': text,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'sentAt': FieldValue.serverTimestamp(),
    'isRead': isRead,
  };
}
