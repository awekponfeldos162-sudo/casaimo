import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final _col = FirebaseFirestore.instance.collection('bookings');

  Stream<List<BookingModel>> watchByGuest(String guestId) {
    return _col
        .where('guestId', isEqualTo: guestId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(BookingModel.fromFirestore).toList());
  }

  Stream<List<BookingModel>> watchByHost(String hostId) {
    return _col
        .where('hostId', isEqualTo: hostId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(BookingModel.fromFirestore).toList());
  }

  Stream<BookingModel?> watchById(String id) {
    return _col
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? BookingModel.fromFirestore(doc) : null);
  }

  Future<BookingModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return BookingModel.fromFirestore(doc);
  }

  Future<void> updateStatus(String id, BookingStatus status, {String? rejectionReason}) async {
    final data = <String, dynamic>{
      'status': status.firestoreName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (rejectionReason != null) data['rejectionReason'] = rejectionReason;
    await _col.doc(id).update(data);
  }

  Future<void> cancel(String id) => updateStatus(id, BookingStatus.cancelled);
}
