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
    this.maxPrice = 500000,
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

final searchResultsProvider = Provider<AsyncValue<List<ListingModel>>>((ref) {
  final filters = ref.watch(searchFiltersProvider);
  return ref.watch(allListingsStreamProvider).whenData((all) {
    var results = all.where((l) {
      if (filters.query.isNotEmpty &&
          !l.title.toLowerCase().contains(filters.query.toLowerCase()) &&
          !l.city.toLowerCase().contains(filters.query.toLowerCase())) {
        return false;
      }
      if (filters.type != null && l.type != filters.type) return false;
      if (l.pricePerNight < filters.minPrice || l.pricePerNight > filters.maxPrice) return false;
      if (filters.minBedrooms != null && l.bedrooms < filters.minBedrooms!) return false;
      if (filters.minBathrooms != null && l.bathrooms < filters.minBathrooms!) return false;
      if (l.avgRating < filters.minRating) return false;
      return true;
    }).toList();

    switch (filters.sortBy) {
      case 'prix_asc':
        results.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
      case 'prix_desc':
        results.sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));
      case 'note':
        results.sort((a, b) => b.avgRating.compareTo(a.avgRating));
      default:
        break;
    }
    return results;
  });
});
