import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pendingApproval,
  confirmed,
  rejected,
  checkedIn,
  completed,
  cancelled,
  active;

  String get label {
    switch (this) {
      case BookingStatus.pendingApproval: return 'En attente';
      case BookingStatus.confirmed:       return 'Confirmée';
      case BookingStatus.rejected:        return 'Refusée';
      case BookingStatus.checkedIn:       return 'Enregistré';
      case BookingStatus.active:          return 'En cours';
      case BookingStatus.completed:       return 'Terminée';
      case BookingStatus.cancelled:       return 'Annulée';
    }
  }

  String get firestoreName {
    switch (this) {
      case BookingStatus.pendingApproval: return 'pending_approval';
      case BookingStatus.confirmed:       return 'confirmed';
      case BookingStatus.rejected:        return 'rejected';
      case BookingStatus.checkedIn:       return 'checked_in';
      case BookingStatus.active:          return 'active';
      case BookingStatus.completed:       return 'completed';
      case BookingStatus.cancelled:       return 'cancelled';
    }
  }

  static BookingStatus fromString(String? s) {
    switch (s) {
      case 'pending_approval': return BookingStatus.pendingApproval;
      case 'confirmed':        return BookingStatus.confirmed;
      case 'rejected':         return BookingStatus.rejected;
      case 'checked_in':       return BookingStatus.checkedIn;
      case 'active':           return BookingStatus.active;
      case 'completed':        return BookingStatus.completed;
      case 'cancelled':        return BookingStatus.cancelled;
      default:                 return BookingStatus.pendingApproval;
    }
  }
}

class BookingModel {
  final String id;
  final String listingId;
  final String listingTitle;
  final String listingImage;
  final String guestId;
  final String guestName;
  final String guestAvatar;
  final String hostId;
  final String hostName;
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
  final String? qrToken;
  final String? rejectionReason;
  final DateTime? checkedInAt;
  final DateTime createdAt;
  final bool hiddenByGuest;
  final bool hiddenByHost;

  const BookingModel({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingImage,
    required this.guestId,
    this.guestName = '',
    this.guestAvatar = '',
    required this.hostId,
    this.hostName = '',
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
    this.qrToken,
    this.rejectionReason,
    this.checkedInAt,
    required this.createdAt,
    this.hiddenByGuest = false,
    this.hiddenByHost = false,
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
      hostName: d['hostName'] ?? '',
      checkIn: (d['checkIn'] as Timestamp).toDate(),
      checkOut: (d['checkOut'] as Timestamp).toDate(),
      guests: d['guests'] ?? 1,
      pricePerNight: (d['pricePerNight'] ?? 0).toDouble(),
      cleaningFee: (d['cleaningFee'] ?? 0).toDouble(),
      serviceFee: (d['serviceFee'] ?? 0).toDouble(),
      total: (d['total'] ?? 0).toDouble(),
      paymentMethod: d['paymentMethod'] ?? '',
      paymentStatus: d['paymentStatus'] ?? 'paid',
      status: BookingStatus.fromString(d['status']),
      qrToken: d['qrToken'] as String?,
      rejectionReason: d['rejectionReason'] as String?,
      checkedInAt: (d['checkedInAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hiddenByGuest: d['hiddenByGuest'] ?? false,
      hiddenByHost: d['hiddenByHost'] ?? false,
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
    'hostName': hostName,
    'checkIn': Timestamp.fromDate(checkIn),
    'checkOut': Timestamp.fromDate(checkOut),
    'guests': guests,
    'pricePerNight': pricePerNight,
    'cleaningFee': cleaningFee,
    'serviceFee': serviceFee,
    'total': total,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'status': status.firestoreName,
    'qrToken': qrToken,
    'rejectionReason': rejectionReason,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
