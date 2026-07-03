import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newBooking,
  bookingConfirmed,
  bookingRejected,
  bookingCheckedIn,
  message,
  review,
  payment,
  info;

  static NotificationType fromString(String? s) => switch (s) {
    'new_booking'         => NotificationType.newBooking,
    'booking_confirmed'   => NotificationType.bookingConfirmed,
    'booking_rejected'    => NotificationType.bookingRejected,
    'booking_checked_in'  => NotificationType.bookingCheckedIn,
    'message'             => NotificationType.message,
    'review'              => NotificationType.review,
    'payment'             => NotificationType.payment,
    _ => NotificationType.info,
  };
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final String? bookingId;
  final String? listingId;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.bookingId,
    this.listingId,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      type: NotificationType.fromString(d['type']),
      isRead: d['isRead'] ?? false,
      bookingId: d['bookingId'] as String?,
      listingId: d['listingId'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
