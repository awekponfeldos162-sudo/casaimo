import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/presentation/providers/listing_provider.dart';

class SearchFilters {
  final String query;
  final String? type;
  final double minPrice;
  final double maxPrice;
  final int? minBedrooms;
  final int? minBathrooms;
  final double minRating;
  final List<String> amenities;
  final String sortBy;

  const SearchFilters({
    this.query = '',
    this.type,
    this.minPrice = 0,
    this.maxPrice = 9999999,
    this.minBedrooms,
    this.minBathrooms,
    this.minRating = 0,
    this.amenities = const [],
    this.sortBy = 'pertinence',
  });

  SearchFilters copyWith({
    String? query, String? type, double? minPrice, double? maxPrice,
    int? minBedrooms, int? minBathrooms, double? minRating,
    List<String>? amenities, String? sortBy,
  }) => SearchFilters(
    query: query ?? this.query,
    type: type ?? this.type,
    minPrice: minPrice ?? this.minPrice,
    maxPrice: maxPrice ?? this.maxPrice,
    minBedrooms: minBedrooms ?? this.minBedrooms,
    minBathrooms: minBathrooms ?? this.minBathrooms,
    minRating: minRating ?? this.minRating,
    amenities: amenities ?? this.amenities,
    sortBy: sortBy ?? this.sortBy,
  );

  SearchFilters reset() => const SearchFilters();
}

final searchFiltersProvider = StateProvider<SearchFilters>((ref) => const SearchFilters());

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = StreamProvider<List<ListingModel>>((ref) {
  final f = ref.watch(searchFiltersProvider);
  return ref.watch(listingRepositoryProvider).watchWithFilters(
    query: f.query,
    type: f.type,
    minPrice: f.minPrice,
    maxPrice: f.maxPrice,
    minBedrooms: f.minBedrooms,
    minBathrooms: f.minBathrooms,
    minRating: f.minRating,
    sortBy: f.sortBy,
  );
});
