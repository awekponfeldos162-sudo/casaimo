import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/presentation/providers/listing_provider.dart';

final featuredListingsProvider = StreamProvider<List<ListingModel>>((ref) {
  return ref.watch(listingRepositoryProvider).watchAll().map(
    (listings) => listings.where((l) => l.avgRating >= 4.5).take(6).toList(),
  );
});

final nearbyListingsProvider = StreamProvider<List<ListingModel>>((ref) {
  return ref.watch(listingRepositoryProvider).watchAll().map(
    (listings) => listings.take(8).toList(),
  );
});

final categoryListingsProvider = StreamProvider<List<ListingModel>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  return ref.watch(listingRepositoryProvider).watchAll().map((listings) {
    if (category == 'Tous') return listings;
    return listings.where((l) => l.type == category).toList();
  });
});

final villasProvider = StreamProvider<List<ListingModel>>((ref) {
  return ref.watch(listingRepositoryProvider).watchAll().map(
    (listings) => listings.where((l) => l.type == 'Villa' || l.type == 'Maison').take(8).toList(),
  );
});

final appsStudiosProvider = StreamProvider<List<ListingModel>>((ref) {
  return ref.watch(listingRepositoryProvider).watchAll().map(
    (listings) => listings.where((l) => l.type == 'Appartement' || l.type == 'Studio').take(8).toList(),
  );
});

final recentlyViewedProvider = StateProvider<List<ListingModel>>((ref) => []);

final selectedCategoryProvider = StateProvider<String>((ref) => 'Tous');

final categoriesProvider = Provider<List<Map<String, dynamic>>>((ref) => [
  {'label': 'Tous', 'icon': '🏠'},
  {'label': 'Villa', 'icon': '🏡'},
  {'label': 'Appartement', 'icon': '🏢'},
  {'label': 'Maison', 'icon': '🏘️'},
  {'label': 'Studio', 'icon': '🛋️'},
  {'label': 'Hôtel', 'icon': '🏨'},
]);
