import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/data/repositories/listing_repository.dart';
import '../../../listing/presentation/providers/listing_provider.dart';
import '../../../../core/services/location_service.dart';

class MapState {
  final List<ListingModel> listings;
  final Position? userPosition;
  final ListingModel? selected;
  final bool isLocating;
  final String? locationError;

  const MapState({
    this.listings = const [],
    this.userPosition,
    this.selected,
    this.isLocating = false,
    this.locationError,
  });

  MapState copyWith({
    List<ListingModel>? listings,
    Position? userPosition,
    ListingModel? selected,
    bool? isLocating,
    String? locationError,
    bool clearSelected = false,
    bool clearError = false,
  }) {
    return MapState(
      listings: listings ?? this.listings,
      userPosition: userPosition ?? this.userPosition,
      selected: clearSelected ? null : (selected ?? this.selected),
      isLocating: isLocating ?? this.isLocating,
      locationError: clearError ? null : (locationError ?? this.locationError),
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  MapNotifier(this._repo) : super(const MapState());

  final ListingRepository _repo;

  void watchListings() {
    _repo.watchAll().listen((listings) {
      state = state.copyWith(listings: listings);
    });
  }

  void selectListing(ListingModel? listing) {
    state = listing == null
        ? state.copyWith(clearSelected: true)
        : state.copyWith(selected: listing);
  }

  Future<void> locateMe() async {
    state = state.copyWith(isLocating: true, clearError: true);
    try {
      final position = await LocationService.getCurrentPosition();
      state = state.copyWith(userPosition: position, isLocating: false);
    } catch (e) {
      state = state.copyWith(isLocating: false, locationError: e.toString().replaceAll('Exception: ', ''));
    }
  }

  LatLng? get userLatLng {
    final pos = state.userPosition;
    if (pos == null) return null;
    return LatLng(pos.latitude, pos.longitude);
  }
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  final repo = ref.read(listingRepositoryProvider);
  final notifier = MapNotifier(repo);
  notifier.watchListings();
  return notifier;
});
