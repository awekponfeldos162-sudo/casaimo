import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../listing/data/models/listing_model.dart';
import '../providers/map_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapCtrl;
  Set<Marker> _markers = {};
  String _filter = 'Tous';
  String? _mapStyle;

  static const _initialCamera = CameraPosition(
    target: LatLng(6.3653, 2.4183),
    zoom: 12,
  );

  final List<String> _filters = ['Tous', 'Chambre', 'Studio', 'Appartement', 'Villa', 'Hôtel'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildMarkers());
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    try {
      final style = await rootBundle.loadString('assets/map_style.json');
      if (mounted) setState(() => _mapStyle = style);
    } catch (_) {}
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    super.dispose();
  }

  List<ListingModel> get _filtered {
    final listings = ref.read(mapProvider).listings;
    if (_filter == 'Tous') return listings;
    return listings.where((l) => l.type.contains(_filter)).toList();
  }

  Future<void> _buildMarkers() async {
    if (!mounted) return;
    final listings = _filtered;
    final state = ref.read(mapProvider);
    final markers = <Marker>{};

    for (final l in listings) {
      if (l.lat == 0 && l.lng == 0) continue;
      final isSelected = state.selected?.id == l.id;
      final icon = await _buildMarkerIcon(l, isSelected: isSelected);
      markers.add(Marker(
        markerId: MarkerId(l.id),
        position: LatLng(l.lat, l.lng),
        icon: icon,
        zIndexInt: isSelected ? 2 : 1,
        onTap: () => ref.read(mapProvider.notifier).selectListing(l),
      ));
    }

    if (mounted) setState(() => _markers = markers);
  }

  Future<BitmapDescriptor> _buildMarkerIcon(ListingModel l, {bool isSelected = false}) async {
    const size = 90.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bgColor = isSelected ? AppColors.primary : Colors.white;
    final textColor = isSelected ? Colors.white : AppColors.primary;

    final bgPaint = Paint()..color = bgColor;
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 0 : 2.5;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Ombre
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(4, 5, size - 4, 36), const Radius.circular(20)),
      shadowPaint,
    );
    // Fond
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, size, 36), const Radius.circular(20)),
      bgPaint,
    );
    if (!isSelected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, size, 36), const Radius.circular(20)),
        borderPaint,
      );
    }

    // Pointe
    final path = Path()
      ..moveTo(size / 2 - 6, 34)
      ..lineTo(size / 2, 44)
      ..lineTo(size / 2 + 6, 34)
      ..close();
    canvas.drawPath(path, bgPaint);
    if (!isSelected) canvas.drawPath(path, borderPaint);

    // Prix
    final label = AppUtils.formatPrice(l.pricePerNight);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size - 8);
    tp.paint(canvas, Offset((size - tp.width) / 2, (36 - tp.height) / 2));

    final img = await recorder.endRecording().toImage(size.toInt(), 48);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  void _onMapCreated(GoogleMapController ctrl) {
    _mapCtrl = ctrl;
  }

  Future<void> _goToUser() async {
    await ref.read(mapProvider.notifier).locateMe();
    final pos = ref.read(mapProvider.notifier).userLatLng;
    if (pos != null) {
      _mapCtrl?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: pos, zoom: 14),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapProvider);

    ref.listen(mapProvider.select((s) => s.listings), (_, _) => _buildMarkers());
    ref.listen(mapProvider.select((s) => s.selected), (_, _) => _buildMarkers());

    return Scaffold(
      body: Stack(
        children: [
          // ── Carte principale ──────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: _initialCamera,
            markers: _markers,
            myLocationEnabled: state.userPosition != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            style: _mapStyle,
            onMapCreated: _onMapCreated,
            onTap: (_) => ref.read(mapProvider.notifier).selectListing(null),
          ),

          // ── Barre du haut ─────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Bouton retour
                      _MapBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: 10),
                      // Titre
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${state.listings.length} logements',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Filtres horizontaux
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final f = _filters[i];
                      final active = _filter == f;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _filter = f);
                          _buildMarkers();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 6)],
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: active ? Colors.white : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── FAB Ma position ───────────────────────────────────────────
          Positioned(
            right: 14,
            bottom: state.selected != null ? 270 : 24,
            child: Column(
              children: [
                _MapBtn(
                  icon: state.isLocating
                      ? Icons.hourglass_top_rounded
                      : Icons.my_location_rounded,
                  onTap: state.isLocating ? null : _goToUser,
                  color: AppColors.primary,
                  iconColor: Colors.white,
                ),
                if (state.locationError != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      state.locationError!,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Carte logement sélectionné ────────────────────────────────
          if (state.selected != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ListingBottomCard(
                listing: state.selected!,
                onClose: () => ref.read(mapProvider.notifier).selectListing(null),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bouton rond carte ──────────────────────────────────────────────────────────

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? iconColor;

  const _MapBtn({required this.icon, this.onTap, this.color, this.iconColor});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 8)],
      ),
      child: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 20),
    ),
  );
}

// ── Fiche logement en bas de carte ────────────────────────────────────────────

class _ListingBottomCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onClose;

  const _ListingBottomCard({required this.listing, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 10),

          // Contenu
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Row(
              children: [
                // Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: listing.mainImage.isNotEmpty
                      ? Image.network(
                          listing.mainImage,
                          width: 90, height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                const SizedBox(width: 12),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              listing.type,
                              style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(onTap: onClose, child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        listing.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              listing.city,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            AppUtils.formatPrice(listing.pricePerNight),
                            style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          const Text(' /nuit', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const Spacer(),
                          if (listing.avgRating > 0)
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
                                const SizedBox(width: 2),
                                Text(listing.avgRating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bouton voir
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/listing/${listing.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                ),
                child: const Text('Voir le logement', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 90, height: 90,
    color: AppColors.primaryContainer,
    child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 36),
  );
}
