import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/cards/search_listing_card.dart';
import '../../../../shared/widgets/layout/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../listing/data/models/listing_model.dart';
import '../providers/search_provider.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  GoogleMapController? _mapCtrl;
  Set<Marker> _markers = {};
  String? _selectedId;

  @override
  void dispose() {
    _mapCtrl?.dispose();
    super.dispose();
  }

  void _buildMarkers(List<ListingModel> listings) {
    final markers = <Marker>{};
    for (final l in listings) {
      if (l.lat == 0 && l.lng == 0) continue;
      final isSelected = _selectedId == l.id;
      markers.add(Marker(
        markerId: MarkerId(l.id),
        position: LatLng(l.lat, l.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRose,
        ),
        zIndexInt: isSelected ? 2 : 1,
        infoWindow: InfoWindow(title: l.title, snippet: l.city),
        onTap: () => setState(() => _selectedId = l.id),
      ));
    }
    if (mounted) setState(() => _markers = markers);

    // Centrer la carte sur les résultats
    if (listings.isNotEmpty && _mapCtrl != null) {
      final valid = listings.where((l) => l.lat != 0 || l.lng != 0).toList();
      if (valid.isNotEmpty) {
        final lat = valid.map((l) => l.lat).reduce((a, b) => a + b) / valid.length;
        final lng = valid.map((l) => l.lng).reduce((a, b) => a + b) / valid.length;
        _mapCtrl!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 11));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final results = resultsAsync.valueOrNull ?? [];
    final filters = ref.watch(searchFiltersProvider);
    final mapsEnabled = AppConstants.mapsEnabled;

    // Rebuild markers when results change
    ref.listen(searchResultsProvider, (_, next) {
      final list = next.valueOrNull ?? [];
      _buildMarkers(list);
    });

    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // ── Carte fixe en arrière-plan ──────────────────────────────────
          if (mapsEnabled)
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(6.3653, 2.4183),
                  zoom: 10,
                ),
                markers: _markers,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (ctrl) {
                  _mapCtrl = ctrl;
                  _buildMarkers(results);
                },
                onTap: (_) => setState(() => _selectedId = null),
              ),
            )
          else
            const Positioned.fill(child: ColoredBox(color: Color(0xFFF5F6FA))),

          // ── Barre de navigation (overlay haut) ─────────────────────────
          Positioned(
            top: topPad + 8,
            left: 12, right: 12,
            child: Row(
              children: [
                _MapBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.go('/search'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 8),
                      ],
                    ),
                    child: Row(children: [
                      const Icon(Icons.search, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.query.isEmpty ? 'Tous les biens' : widget.query,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ── Panneau de résultats (scroll par-dessus la carte) ───────────
          DraggableScrollableSheet(
            initialChildSize: mapsEnabled ? 0.46 : 0.88,
            minChildSize: mapsEnabled ? 0.15 : 0.88,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: mapsEnabled ? const [0.15, 0.46, 0.92] : const [0.88, 0.92],
            builder: (_, scrollCtrl) => DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: CustomScrollView(
                controller: scrollCtrl,
                slivers: [
                  // Poignée
                  SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // Compteur + filtres + tri
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
                      child: Row(
                        children: [
                          if (resultsAsync.isLoading)
                            const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          else
                            Text(
                              '${results.length} résultat${results.length > 1 ? 's' : ''}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 14),
                            ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _showFilters(context, ref),
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: const Text('Filtres'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                          ),
                          TextButton.icon(
                            onPressed: () => _showSort(context, ref, filters.sortBy),
                            icon: const Icon(Icons.sort_rounded, size: 16),
                            label: const Text('Trier'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Résultats
                  if (resultsAsync.isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  else if (results.isEmpty)
                    SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Aucun résultat',
                        subtitle: 'Essayez de modifier vos filtres ou votre recherche.',
                        actionLabel: 'Modifier les filtres',
                        onAction: () => context.go('/search'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverList.builder(
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final l = results[i];
                          final isHighlighted = _selectedId == l.id;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: isHighlighted
                                ? BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppColors.primary, width: 2),
                                  )
                                : null,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: SearchListingCard(
                              listing: l,
                              isFavorite: ref.watch(authProvider)?.favoriteIds.contains(l.id) ?? false,
                              onTap: () => context.push('/listing/${l.id}'),
                              onFavorite: () => ref.read(authProvider.notifier).toggleFavorite(l.id),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSort(BuildContext context, WidgetRef ref, String current) {
    const options = [
      ('pertinence', 'Pertinence'),
      ('prix_asc', 'Prix croissant'),
      ('prix_desc', 'Prix décroissant'),
      ('note', 'Mieux notés'),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Trier par', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          ...options.map((o) => ListTile(
            title: Text(o.$2),
            trailing: current == o.$1 ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () {
              ref.read(searchFiltersProvider.notifier).update((s) => s.copyWith(sortBy: o.$1));
              Navigator.pop(context);
            },
          )),
        ]),
      ),
    );
  }

  void _showFilters(BuildContext context, WidgetRef ref) {
    context.go('/search');
  }
}

// ── Bouton rond overlay carte ─────────────────────────────────────────────────

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MapBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 8)],
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 18),
    ),
  );
}
