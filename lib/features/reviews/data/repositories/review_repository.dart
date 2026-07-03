import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final _col = FirebaseFirestore.instance.collection('reviews');
  final _listingsCol = FirebaseFirestore.instance.collection('listings');

  Stream<List<ReviewModel>> watchByListing(String listingId) {
    return _col
        .where('listingId', isEqualTo: listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ReviewModel.fromFirestore).toList());
  }

  Future<bool> hasReviewedBooking(String bookingId, String guestId) async {
    final snap = await _col
        .where('bookingId', isEqualTo: bookingId)
        .where('guestId', isEqualTo: guestId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> submitReview(ReviewModel review) async {
    await _col.add(review.toFirestore());
    await _updateListingRating(review.listingId);
  }

  Future<void> _updateListingRating(String listingId) async {
    final snap = await _col.where('listingId', isEqualTo: listingId).get();
    if (snap.docs.isEmpty) return;
    final ratings = snap.docs
        .map((d) => (d.data()['rating'] as num?)?.toDouble() ?? 0)
        .toList();
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;
    await _listingsCol.doc(listingId).update({
      'avgRating': double.parse(avg.toStringAsFixed(1)),
      'reviewCount': ratings.length,
    });
  }
}
