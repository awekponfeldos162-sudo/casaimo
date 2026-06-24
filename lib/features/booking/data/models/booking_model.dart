import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, active, completed, cancelled }

class BookingModel {
  final String id;
  final String listingId;
  final String listingTitle;
  final String listingImage;
  final String guestId;
  final String guestName;
  final String guestAvatar;
  final String hostId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double pricePerNight;
  final double cleaningFee;
  final double serviceFee;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final BookingStatus status;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingImage,
    required this.guestId,
    this.guestName = '',
    this.guestAvatar = '',
    required this.hostId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.pricePerNight,
    required this.cleaningFee,
    required this.serviceFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
  });

  int get nights => checkOut.difference(checkIn).inDays;

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      listingId: d['listingId'] ?? '',
      listingTitle: d['listingTitle'] ?? '',
      listingImage: d['listingImage'] ?? '',
      guestId: d['guestId'] ?? '',
      guestName: d['guestName'] ?? '',
      guestAvatar: d['guestAvatar'] ?? '',
      hostId: d['hostId'] ?? '',
      checkIn: (d['checkIn'] as Timestamp).toDate(),
      checkOut: (d['checkOut'] as Timestamp).toDate(),
      guests: d['guests'] ?? 1,
      pricePerNight: (d['pricePerNight'] ?? 0).toDouble(),
      cleaningFee: (d['cleaningFee'] ?? 0).toDouble(),
      serviceFee: (d['serviceFee'] ?? 0).toDouble(),
      total: (d['total'] ?? 0).toDouble(),
      paymentMethod: d['paymentMethod'] ?? '',
      paymentStatus: d['paymentStatus'] ?? 'pending',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'listingId': listingId,
    'listingTitle': listingTitle,
    'listingImage': listingImage,
    'guestId': guestId,
    'guestName': guestName,
    'guestAvatar': guestAvatar,
    'hostId': hostId,
    'checkIn': Timestamp.fromDate(checkIn),
    'checkOut': Timestamp.fromDate(checkOut),
    'guests': guests,
    'pricePerNight': pricePerNight,
    'cleaningFee': cleaningFee,
    'serviceFee': serviceFee,
    'total': total,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'status': status.name,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
