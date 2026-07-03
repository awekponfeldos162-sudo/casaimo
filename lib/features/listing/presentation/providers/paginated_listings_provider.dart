import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_constants.dart';
import '../../data/models/listing_model.dart';
import '../../data/repositories/listing_repository.dart';
import 'listing_provider.dart';

class PaginatedState {
  final List<ListingModel> listings;
  final bool isLoading;
  final bool hasMore;

  const PaginatedState({
    this.listings = const [],
    this.isLoading = false,
    this.hasMore = true,
  });

  PaginatedState copyWith({List<ListingModel>? listings, bool? isLoading, bool? hasMore}) =>
      PaginatedState(
        listings: listings ?? this.listings,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
      );
}

class PaginatedListingsNotifier extends StateNotifier<PaginatedState> {
  PaginatedListingsNotifier(this._repo) : super(const PaginatedState()) {
    _fetchFirst();
  }

  final ListingRepository _repo;
  DocumentSnapshot? _lastDoc;

  Future<void> _fetchFirst() async {
    state = state.copyWith(isLoading: true);
    final (listings, last) = await _repo.fetchPaginated();
    _lastDoc = last;
    state = PaginatedState(
      listings: listings,
      isLoading: false,
      hasMore: listings.length >= AppConstants.pageSize,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || _lastDoc == null) return;
    state = state.copyWith(isLoading: true);
    final (more, last) = await _repo.fetchPaginated(startAfter: _lastDoc);
    if (last != null) _lastDoc = last;
    state = state.copyWith(
      listings: [...state.listings, ...more],
      isLoading: false,
      hasMore: more.length >= AppConstants.pageSize,
    );
  }

  Future<void> refresh() async {
    _lastDoc = null;
    state = const PaginatedState();
    await _fetchFirst();
  }
}

final paginatedListingsProvider =
    StateNotifierProvider<PaginatedListingsNotifier, PaginatedState>((ref) {
  return PaginatedListingsNotifier(ref.watch(listingRepositoryProvider));
});
