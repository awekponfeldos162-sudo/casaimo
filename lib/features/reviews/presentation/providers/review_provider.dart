import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) => ReviewRepository());

final listingReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, listingId) {
  return ref.watch(reviewRepositoryProvider).watchByListing(listingId);
});

final hasReviewedProvider = FutureProvider.family<bool, ({String bookingId, String guestId})>((ref, args) {
  return ref.watch(reviewRepositoryProvider).hasReviewedBooking(args.bookingId, args.guestId);
});
