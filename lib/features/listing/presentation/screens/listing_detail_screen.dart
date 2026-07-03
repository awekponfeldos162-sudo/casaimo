import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/layout/empty_state.dart';
import '../../../../shared/widgets/layout/shimmer_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../host/presentation/providers/host_provider.dart';
import '../../data/models/listing_model.dart';
import '../providers/listing_provider.dart';
import '../../../reviews/data/models/review_model.dart';
import '../../../reviews/presentation/providers/review_provider.dart';
import '../../../messaging/data/repositories/conversation_repository.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  late PageController _pageCtrl;
  int _imageIndex = 0;
  bool _showFullDesc = false;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingByIdProvider(widget.listingId));
    final isFav = ref.watch(authProvider)?.favoriteIds.contains(widget.listingId) ?? false;

    return listingAsync.when(
      loading: () => const Scaffold(body: ShimmerLoader()),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Erreur: $e'))),
      data: (listing) {
        if (listing == null) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState(icon: Icons.home_outlined, title: 'Bien introuvable', actionLabel: 'Retour', onAction: () => context.pop()),
          );
        }
        final hostAsync = ref.watch(hostByIdProvider(listing.hostId));
        final otherListingsAsync = ref.watch(hostListingsStreamProvider(listing.hostId));
        return _buildDetail(context, listing, isFav, hostAsync, otherListingsAsync);
      },
    );
  }

  Widget _buildDetail(
    BuildContext context,
    ListingModel listing,
    bool isFav,
    AsyncValue hostAsync,
    AsyncValue<List<ListingModel>> otherListingsAsync,
  ) {
    final others = otherListingsAsync.valueOrNull
        ?.where((l) => l.id != listing.id)
        .toList() ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Media gallery ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.black,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(margin: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.arrow_back_rounded, color: Colors.black)),
            ),
            actions: [
              GestureDetector(
                onTap: () {},
                child: Container(margin: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.share_rounded, color: Colors.black, size: 20))),
              ),
              GestureDetector(
                onTap: () => ref.read(authProvider.notifier).toggleFavorite(listing.id),
                child: Container(margin: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Padding(padding: const EdgeInsets.all(8), child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? Colors.red : Colors.black, size: 20))),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: listing.mediaUrls.isEmpty
                  ? Container(color: AppColors.surfaceVariant, child: const Icon(Icons.home_rounded, size: 80, color: AppColors.textHint))
                  : PageView.builder(
                      controller: _pageCtrl,
                      itemCount: listing.mediaUrls.length + (listing.hasVideo ? 1 : 0),
                      onPageChanged: (i) => setState(() => _imageIndex = i),
                      itemBuilder: (context, i) {
                        if (listing.hasVideo && i == 0) {
                          return _VideoCarouselItem(
                            videoUrl: listing.videoUrl,
                            thumbnail: listing.mainImage,
                          );
                        }
                        final photoIndex = i - (listing.hasVideo ? 1 : 0);
                        return CachedNetworkImage(
                          imageUrl: listing.mediaUrls[photoIndex],
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Container(color: AppColors.surfaceVariant),
                          errorWidget: (ctx, url, err) => Container(color: AppColors.surfaceVariant),
                        );
                      },
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Bande miniatures
              if (listing.mediaUrls.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    height: 62,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: listing.mediaUrls.length + (listing.hasVideo ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final isActive = i == _imageIndex;
                        final url = (listing.hasVideo && i == 0)
                            ? listing.mainImage
                            : listing.mediaUrls[i - (listing.hasVideo ? 1 : 0)];
                        return GestureDetector(
                          onTap: () => _pageCtrl.animateToPage(i,
                              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 62, height: 62,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive ? AppColors.primary : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isActive
                                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 6)]
                                  : [],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(fit: StackFit.expand, children: [
                                CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                                if (listing.hasVideo && i == 0)
                                  Container(
                                    color: Colors.black26,
                                    child: const Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22)),
                                  ),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Title + price
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(6)),
                          child: Text(listing.type, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 6),
                        Text(listing.title, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(child: Text('${listing.address}, ${listing.city}', style: Theme.of(context).textTheme.bodySmall)),
                        ]),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(AppUtils.formatPrice(listing.pricePerNight), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const Text('/ nuit', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      if (listing.pricePerMonth > 0) ...[
                        const SizedBox(height: 2),
                        Text(AppUtils.formatPrice(listing.pricePerMonth), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const Text('/ mois', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ]),
                  ]),
                  const SizedBox(height: 10),

                  // Specs
                  Row(children: [
                    _SpecChip(icon: Icons.bed_rounded, label: '${listing.bedrooms} Ch.'),
                    const SizedBox(width: 8),
                    _SpecChip(icon: Icons.bathtub_outlined, label: '${listing.bathrooms} Sdb'),
                    const SizedBox(width: 8),
                    _SpecChip(icon: Icons.people_rounded, label: '${listing.maxGuests} pers.'),
                  ]),
                  const SizedBox(height: 10),

                  // Rating
                  Row(children: [
                    RatingBarIndicator(
                      rating: listing.avgRating,
                      itemCount: 5, itemSize: 18,
                      itemBuilder: (ctx, i) => const Icon(Icons.star_rounded, color: AppColors.star),
                    ),
                    const SizedBox(width: 8),
                    Text('${listing.avgRating.toStringAsFixed(1)} (${listing.reviewCount} avis)', style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ]),
              ),

              // ── Description ──────────────────────────────────────────
              if (listing.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      _showFullDesc ? listing.description : AppUtils.truncate(listing.description, 200),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55, color: AppColors.textSecondary),
                    ),
                    if (listing.description.length > 200) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => setState(() => _showFullDesc = !_showFullDesc),
                        child: Text(
                          _showFullDesc ? 'Voir moins ▲' : 'Voir plus ▼',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ]),
                ),

              // ── Équipements ───────────────────────────────────────────
              if (listing.amenities.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Équipements', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: listing.amenities.map((a) => Chip(
                        label: Text(a, style: const TextStyle(fontSize: 12)),
                        avatar: const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
                        backgroundColor: AppColors.primaryContainer,
                        side: BorderSide.none,
                      )).toList(),
                    ),
                  ]),
                ),

              // ── Avis ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Avis', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    if (listing.reviewCount > 0)
                      TextButton(
                        onPressed: () => context.push(
                          '/reviews/${listing.id}',
                          extra: {'title': listing.title},
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Voir tous (${listing.reviewCount})', style: const TextStyle(fontSize: 13)),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: AppColors.star, size: 32),
                    const SizedBox(width: 8),
                    Text(listing.avgRating.toStringAsFixed(1), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Text('/ 5  (${listing.reviewCount} avis)', style: Theme.of(context).textTheme.bodyMedium),
                  ]),
                  const SizedBox(height: 12),
                  ...ref.watch(listingReviewsProvider(listing.id))
                      .valueOrNull
                      ?.take(3)
                      .map((r) => _ReviewMiniCard(review: r))
                      .toList() ?? [],
                  if (listing.reviewCount == 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Aucun avis pour le moment.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ),
                ]),
              ),

              // ── Politique ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Politique', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _PolicyRow(icon: Icons.cancel_outlined, label: 'Annulation', value: listing.cancellationPolicy),
                  const SizedBox(height: 10),
                  _PolicyRow(icon: Icons.calendar_today_rounded, label: 'Séjour min', value: '${listing.minStay} nuit${listing.minStay > 1 ? 's' : ''}'),
                  const SizedBox(height: 10),
                  _PolicyRow(icon: Icons.calendar_month_rounded, label: 'Séjour max', value: '${listing.maxStay} nuits'),
                ]),
              ),
            ]),
          ),

          // ── Carte propriétaire ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _HostCard(
                listing: listing,
                otherCount: others.length + 1,
                onViewAll: () => context.push('/host-profile/${listing.hostId}'),
                onMessage: () async {
                  final user = ref.read(authProvider);
                  if (user == null) return;
                  final convId = await ConversationRepository().createOrGet(
                    user.id, listing.hostId, listing.id, listing.title,
                    hostName: listing.hostName,
                    hostPhone: listing.hostPhone,
                    hostAvatar: listing.hostAvatarUrl,
                  );
                  if (context.mounted) context.push('/chat/$convId');
                },
                onPhone: listing.hostPhone.isNotEmpty ? () => _openContact('tel:${listing.hostPhone}') : null,
                onEmail: listing.hostEmail.isNotEmpty ? () => _openContact('mailto:${listing.hostEmail}') : null,
              ),
            ),
          ),

          // ── Voir plus d'offres ──────────────────────────────────────────
          if (others.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GestureDetector(
                  onTap: () => _showHostListingsSheet(context, listing, others),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      const Icon(Icons.home_work_rounded, color: Colors.white, size: 26),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          'Voir plus d\'offres de ${listing.hostName.isNotEmpty ? listing.hostName : 'ce propriétaire'}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${others.length} autre${others.length > 1 ? 's' : ''} logement${others.length > 1 ? 's' : ''} disponible${others.length > 1 ? 's' : ''}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ])),
                      const SizedBox(width: 10),
                      const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 28),
                    ]),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ── Bottom CTA ────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(AppUtils.formatPrice(listing.pricePerNight), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const Text('/ nuit', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.push('/booking/${listing.id}'),
              child: const Text('Réserver maintenant'),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _openContact(String uriString) async {
    final uri = Uri.tryParse(uriString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showHostListingsSheet(BuildContext context, ListingModel listing, List<ListingModel> listings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.6, 0.92],
        builder: (sheetCtx, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, -4))],
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'Offres de ${listing.hostName.isNotEmpty ? listing.hostName : 'ce propriétaire'}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${listings.length} logement${listings.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ])),
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    context.push('/host-profile/${listing.hostId}');
                  },
                  child: const Text('Voir profil'),
                ),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: listings.length,
                itemBuilder: (ctx, i) => _OtherListingCard(
                  listing: listings[i],
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    context.push('/listing/${listings[i].id}');
                  },
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Carte hôte complète ────────────────────────────────────────────────────

class _HostCard extends StatelessWidget {
  final ListingModel listing;
  final int otherCount;
  final VoidCallback onViewAll;
  final VoidCallback onMessage;
  final VoidCallback? onPhone;
  final VoidCallback? onEmail;
  const _HostCard({
    required this.listing,
    required this.otherCount,
    required this.onViewAll,
    required this.onMessage,
    this.onPhone,
    this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    final name = listing.hostName.isNotEmpty ? listing.hostName : 'Propriétaire';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 8),
      const SizedBox(height: 16),

      // Section label
      Row(children: [
        const Icon(Icons.business_rounded, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('Publié par', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
      ]),
      const SizedBox(height: 12),

      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── En-tête : avatar + nom + badge + type ──────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Avatar / logo
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3), width: 2),
                ),
                child: listing.hostAvatarUrl.isNotEmpty
                    ? ClipOval(child: Image.network(listing.hostAvatarUrl, fit: BoxFit.cover,
                        errorBuilder: (ctx, url, err) => Center(child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))))))
                    : Center(child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1565C0)))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Nom + badge vérifié
                  Row(children: [
                    Flexible(
                      child: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (listing.hostIsVerified) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(6)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.verified_rounded, color: Color(0xFF1565C0), size: 13),
                          SizedBox(width: 3),
                          Text('Vérifié', style: TextStyle(color: Color(0xFF1565C0), fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ],
                  ]),
                  if (listing.hostBusinessType.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(6)),
                      child: Text(listing.hostBusinessType, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Nb d'annonces
                  Text('$otherCount offre${otherCount > 1 ? 's' : ''} publiée${otherCount > 1 ? 's' : ''}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 18),
                ),
              ),
            ]),
          ),

          // ── Coordonnées ────────────────────────────────────────────
          if (listing.hostBusinessAddress.isNotEmpty || listing.hostPhone.isNotEmpty || listing.hostEmail.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(children: [
                if (listing.hostBusinessAddress.isNotEmpty)
                  _ContactRow(icon: Icons.location_on_rounded, value: listing.hostBusinessAddress, color: AppColors.primary),
                if (listing.hostPhone.isNotEmpty)
                  _ContactRow(
                    icon: Icons.phone_rounded,
                    value: listing.hostPhone,
                    color: const Color(0xFF2E7D32),
                    onTap: onPhone,
                    actionLabel: 'Appeler',
                  ),
                if (listing.hostEmail.isNotEmpty)
                  _ContactRow(
                    icon: Icons.email_rounded,
                    value: listing.hostEmail,
                    color: const Color(0xFF1565C0),
                    onTap: onEmail,
                    actionLabel: 'Email',
                  ),
              ]),
            ),
          ],

          // ── Actions ────────────────────────────────────────────────
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMessage,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Message'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.home_work_rounded, size: 16, color: Colors.white),
                  label: const Text('Toutes les offres', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final String? actionLabel;
  const _ContactRow({required this.icon, required this.value, required this.color, this.onTap, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (onTap != null && actionLabel != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(actionLabel!, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OtherListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;
  const _OtherListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: listing.mainImage.isNotEmpty
                  ? CachedNetworkImage(imageUrl: listing.mainImage, height: 110, width: 160, fit: BoxFit.cover)
                  : Container(height: 110, color: AppColors.surfaceVariant, child: const Icon(Icons.home_rounded, color: AppColors.textHint, size: 32)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(4)),
                  child: Text(listing.type, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 4),
                Text(listing.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 12, color: AppColors.star),
                  const SizedBox(width: 2),
                  Text('${listing.avgRating}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 4),
                Text(AppUtils.formatPrice(listing.pricePerNight), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const Text('/nuit', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PolicyRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 20, color: AppColors.textSecondary),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
      Text(value, style: Theme.of(context).textTheme.titleSmall),
    ]);
  }
}

// ── Carte avis mini ───────────────────────────────────────────────────────────
class _ReviewMiniCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewMiniCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: review.guestAvatar.isNotEmpty ? NetworkImage(review.guestAvatar) : null,
              child: review.guestAvatar.isEmpty ? Text(review.guestName.isNotEmpty ? review.guestName[0].toUpperCase() : '?') : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(review.guestName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
              const SizedBox(width: 2),
              Text(review.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ]),
          const SizedBox(height: 8),
          Text(review.text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(AppUtils.formatDate(review.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ]),
      ),
    );
  }
}

// ── Lecteur vidéo inline dans le carousel ─────────────────────────────────────
class _VideoCarouselItem extends StatefulWidget {
  final String videoUrl;
  final String thumbnail;
  const _VideoCarouselItem({required this.videoUrl, required this.thumbnail});

  @override
  State<_VideoCarouselItem> createState() => _VideoCarouselItemState();
}

class _VideoCarouselItemState extends State<_VideoCarouselItem> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
    _ctrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _togglePlay() {
    _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play();
  }

  void _toggleMute() {
    setState(() { _muted = !_muted; });
    _ctrl.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _ctrl.value.isPlaying;

    return Container(
      color: Colors.black,
      child: Stack(fit: StackFit.expand, children: [

        // Miniature pendant le chargement
        if (!_initialized && widget.thumbnail.isNotEmpty)
          CachedNetworkImage(imageUrl: widget.thumbnail, fit: BoxFit.cover),

        // Lecteur vidéo
        if (_initialized)
          Center(
            child: AspectRatio(
              aspectRatio: _ctrl.value.aspectRatio,
              child: VideoPlayer(_ctrl),
            ),
          ),

        // Gradient bas
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),

        // Bouton play/pause central (visible uniquement quand en pause)
        if (!isPlaying)
          Center(
            child: GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12)],
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 40, color: Colors.black87),
              ),
            ),
          ),

        // Tap pour pause quand en lecture
        if (isPlaying)
          GestureDetector(onTap: _togglePlay, child: const ColoredBox(color: Colors.transparent)),

        // Indicateur de chargement
        if (!_initialized)
          const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),

        // Barre de contrôles bas
        Positioned(
          bottom: 6, left: 12, right: 12,
          child: Row(children: [
            // Badge vidéo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.videocam_rounded, color: Colors.white, size: 13),
                SizedBox(width: 4),
                Text('Vidéo', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
            const Spacer(),
            // Bouton muet
            GestureDetector(
              onTap: _toggleMute,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white, size: 16,
                ),
              ),
            ),
          ]),
        ),

        // Barre de progression
        if (_initialized)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: VideoProgressIndicator(
              _ctrl,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: AppColors.primary,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                bufferedColor: Colors.white.withValues(alpha: 0.5),
              ),
              padding: EdgeInsets.zero,
            ),
          ),
      ]),
    );
  }
}
