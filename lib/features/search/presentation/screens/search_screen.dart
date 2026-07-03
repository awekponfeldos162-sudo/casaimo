import 'dart:async';
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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  GoogleMapController? _mapCtrl;
  Set<Marker> _markers = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl.text = ref.read(searchFiltersProvider).query;
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(searchFiltersProvider.notifier).update((s) => s.copyWith(query: val));
      }
    });
  }

  void _buildMarkers(List<ListingModel> listings) {
    final markers = <Marker>{};
    for (final l in listings) {
      if (l.lat == 0 && l.lng == 0) continue;
      markers.add(Marker(
        markerId: MarkerId(l.id),
        position: LatLng(l.lat, l.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: l.title, snippet: l.city),
      ));
    }
    if (!mounted) return;
    setState(() => _markers = markers);

    final valid = listings.where((l) => l.lat != 0 || l.lng != 0).toList();
    if (valid.isNotEmpty && _mapCtrl != null) {
      final lat = valid.map((l) => l.lat).reduce((a, b) => a + b) / valid.length;
      final lng = valid.map((l) => l.lng).reduce((a, b) => a + b) / valid.length;
      _mapCtrl!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 11));
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final results = resultsAsync.valueOrNull ?? [];
    final mapsEnabled = AppConstants.mapsEnabled;

    ref.listen(searchResultsProvider, (_, next) {
      _buildMarkers(next.valueOrNull ?? []);
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
              ),
            )
          else
            const Positioned.fill(child: ColoredBox(color: Color(0xFFF5F6FA))),

          // ── Barre de recherche (overlay haut) ──────────────────────────
          Positioned(
            top: topPad + 8,
            left: 12, right: 12,
            child: _SearchBar(
              controller: _ctrl,
              onChanged: _onSearchChanged,
              onFilter: () => _showFilters(context),
              flat: !mapsEnabled,
            ),
          ),

          // ── Suggestions rapides (sous la barre de recherche) ────────────
          if (_ctrl.text.isEmpty)
            Positioned(
              top: topPad + 72,
              left: 0, right: 0,
              height: 40,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                children: ['Cotonou', 'Lomé', 'Abidjan', 'Dakar', 'Villa', 'Piscine', 'Centre-ville']
                    .map((q) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(q, style: const TextStyle(fontSize: 12)),
                            avatar: const Icon(Icons.search_rounded, size: 13),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.white,
                            onPressed: () {
                              _ctrl.text = q;
                              _onSearchChanged(q);
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),

          // ── Panneau de cartes (scroll par-dessus la carte) ──────────────
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

                  // Compteur + filtres
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
                      child: Row(children: [
                        if (resultsAsync.isLoading)
                          const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        else
                          Text(
                            '${results.length} logement${results.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _showFilters(context),
                          icon: const Icon(Icons.tune_rounded, size: 16),
                          label: const Text('Filtres'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                        ),
                      ]),
                    ),
                  ),

                  // Cartes
                  if (resultsAsync.isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  else if (results.isEmpty)
                    SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Aucun résultat',
                        subtitle: 'Essayez de modifier vos critères.',
                        actionLabel: 'Réinitialiser',
                        onAction: () {
                          _ctrl.clear();
                          ref.read(searchFiltersProvider.notifier).state = const SearchFilters();
                        },
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverList.builder(
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final l = results[i];
                          return SearchListingCard(
                            listing: l,
                            isFavorite: ref.watch(authProvider)?.favoriteIds.contains(l.id) ?? false,
                            onTap: () => context.push('/listing/${l.id}'),
                            onFavorite: () => ref.read(authProvider.notifier).toggleFavorite(l.id),
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

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _FiltersSheet(),
    );
  }
}

// ── Barre de recherche ────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;
  final bool flat;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onFilter,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final shadow = flat
        ? <BoxShadow>[]
        : <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 10)];
    final border = flat ? Border.all(color: AppColors.border) : null;

    return Row(children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: shadow,
            border: border,
          ),
          child: Row(children: [
            const Icon(Icons.search, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Ville, quartier, type...',
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
              ),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: onFilter,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: shadow,
            border: border,
          ),
          child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
        ),
      ),
    ]);
  }
}

// ── Feuille de filtres ────────────────────────────────────────────────────────

class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet();

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late SearchFilters _local;
  late TextEditingController _minCtrl;
  late TextEditingController _maxCtrl;

  static const _presets = [
    (label: '– 25 000', min: 0.0, max: 25000.0),
    (label: '25k – 75k', min: 25000.0, max: 75000.0),
    (label: '75k – 200k', min: 75000.0, max: 200000.0),
    (label: '200k – 500k', min: 200000.0, max: 500000.0),
    (label: '500k +', min: 500000.0, max: 9999999.0),
  ];

  @override
  void initState() {
    super.initState();
    _local = ref.read(searchFiltersProvider);
    _minCtrl = TextEditingController(
        text: _local.minPrice > 0 ? _local.minPrice.toInt().toString() : '');
    _maxCtrl = TextEditingController(
        text: (_local.maxPrice < 9999999 && _local.maxPrice != 500000)
            ? _local.maxPrice.toInt().toString()
            : '');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(double min, double max) {
    setState(() {
      _local = _local.copyWith(minPrice: min, maxPrice: max);
      _minCtrl.text = min > 0 ? min.toInt().toString() : '';
      _maxCtrl.text = max < 9999999 ? max.toInt().toString() : '';
    });
  }

  void _onPriceChanged() {
    final min = double.tryParse(_minCtrl.text) ?? 0;
    final max = double.tryParse(_maxCtrl.text) ?? 9999999;
    setState(() =>
        _local = _local.copyWith(minPrice: min, maxPrice: max < min ? min : max));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40, height: 4,
          decoration:
              BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Filtres', style: Theme.of(context).textTheme.headlineSmall),
            TextButton(
              onPressed: () => setState(() {
                _local = _local.reset();
                _minCtrl.text = '';
                _maxCtrl.text = '';
              }),
              child: const Text('Réinitialiser'),
            ),
          ]),
        ),
        const Divider(),
        Expanded(
          child: ListView(controller: scrollCtrl, padding: const EdgeInsets.all(20), children: [
            // Prix
            Text('Budget / nuit (FCFA)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _minCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _onPriceChanged(),
                  decoration: InputDecoration(
                    labelText: 'Min', hintText: '0', suffixText: 'FCFA',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('→', style: TextStyle(fontSize: 18, color: Colors.grey.shade400)),
              ),
              Expanded(
                child: TextField(
                  controller: _maxCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _onPriceChanged(),
                  decoration: InputDecoration(
                    labelText: 'Max', hintText: 'Sans limite', suffixText: 'FCFA',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 6,
              children: _presets.map((p) {
                final isActive = _local.minPrice == p.min && _local.maxPrice == p.max;
                return GestureDetector(
                  onTap: () => _applyPreset(p.min, p.max),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isActive ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(p.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? Colors.white : AppColors.textPrimary,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Type
            Text('Type de bien', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              'Tous', ...AppConstants.listingTypes,
            ].map((t) {
              final selected = t == 'Tous' ? _local.type == null : _local.type == t;
              return ChoiceChip(
                label: Text(t),
                selected: selected,
                onSelected: (_) => setState(
                    () => _local = _local.copyWith(type: t == 'Tous' ? null : t)),
                selectedColor: AppColors.primaryContainer,
              );
            }).toList()),
            const SizedBox(height: 20),

            _CounterRow(
              label: 'Chambres min.',
              value: _local.minBedrooms ?? 0,
              onChanged: (v) => setState(
                  () => _local = _local.copyWith(minBedrooms: v == 0 ? null : v)),
            ),
            const SizedBox(height: 12),
            _CounterRow(
              label: 'Salles de bain min.',
              value: _local.minBathrooms ?? 0,
              onChanged: (v) => setState(
                  () => _local = _local.copyWith(minBathrooms: v == 0 ? null : v)),
            ),
            const SizedBox(height: 20),

            Text('Note minimale', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [0, 3, 4, 4.5].map((r) {
              final rr = r.toDouble();
              return ChoiceChip(
                label: Text(r == 0 ? 'Toutes' : '⭐ $r+'),
                selected: _local.minRating == rr,
                onSelected: (_) =>
                    setState(() => _local = _local.copyWith(minRating: rr)),
                selectedColor: AppColors.primaryContainer,
              );
            }).toList()),
            const SizedBox(height: 32),
          ]),
        ),
        Padding(
          padding:
              EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
          child: ElevatedButton(
            onPressed: () {
              ref.read(searchFiltersProvider.notifier).state = _local;
              Navigator.pop(context);
            },
            child: const Text('Appliquer les filtres'),
          ),
        ),
      ]),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _CounterRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      Row(children: [
        _CircleBtn(icon: Icons.remove, onTap: value > 0 ? () => onChanged(value - 1) : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$value', style: Theme.of(context).textTheme.titleMedium),
        ),
        _CircleBtn(icon: Icons.add, onTap: () => onChanged(value + 1)),
      ]),
    ]);
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: onTap != null ? AppColors.primary : AppColors.border),
      ),
      child: Icon(icon,
          size: 16,
          color: onTap != null ? AppColors.primary : AppColors.textHint),
    ),
  );
}
