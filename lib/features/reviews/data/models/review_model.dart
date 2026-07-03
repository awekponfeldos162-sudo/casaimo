import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String listingId;
  final String bookingId;
  final String guestId;
  final String guestName;
  final String guestAvatar;
  final double rating;
  final String text;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.listingId,
    required this.bookingId,
    required this.guestId,
    required this.guestName,
    required this.guestAvatar,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      listingId: d['listingId'] ?? '',
      bookingId: d['bookingId'] ?? '',
      guestId: d['guestId'] ?? '',
      guestName: d['guestName'] ?? '',
      guestAvatar: d['guestAvatar'] ?? '',
      rating: (d['rating'] ?? 0).toDouble(),
      text: d['text'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'listingId': listingId,
    'bookingId': bookingId,
    'guestId': guestId,
    'guestName': guestName,
    'guestAvatar': guestAvatar,
    'rating': rating,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
