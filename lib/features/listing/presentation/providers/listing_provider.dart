import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/listing_model.dart';
import '../../data/repositories/listing_repository.dart';

final listingRepositoryProvider = Provider<ListingRepository>(
  (_) => ListingRepository(),
);

final allListingsStreamProvider = StreamProvider<List<ListingModel>>((ref) {
  return ref.watch(listingRepositoryProvider).watchAll();
});

final listingByIdProvider = FutureProvider.family<ListingModel?, String>(
  (ref, id) => ref.watch(listingRepositoryProvider).getById(id),
);

final hostListingsStreamProvider = StreamProvider.family<List<ListingModel>, String>(
  (ref, hostId) => ref.watch(listingRepositoryProvider).watchByHost(hostId),
);
