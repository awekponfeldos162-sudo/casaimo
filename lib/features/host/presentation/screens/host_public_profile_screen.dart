import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/layout/call_options_sheet.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/presentation/providers/listing_provider.dart';
import '../providers/host_provider.dart';

class HostPublicProfileScreen extends ConsumerWidget {
  final String hostId;
  const HostPublicProfileScreen({super.key, required this.hostId});

  Future<void> _openChat(
    BuildContext context,
    WidgetRef ref,
    UserModel host,
    String displayName,
  ) async {
    final currentUser = ref.read(authProvider);
    if (currentUser == null) {
      if (context.mounted) context.go('/login');
      return;
    }
    // Stable conversation ID = sorted participant IDs joined
    final ids = [currentUser.id, host.id]..sort();
    final convId = ids.join('_');

    await FirebaseFirestore.instance.collection('messages').doc(convId).set({
      'participants': [currentUser.id, host.id],
      'listingId': '',
      'listingTitle': 'Contact avec $displayName',
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': {currentUser.id: 0, host.id: 0},
      'hostId': host.id,
      'hostName': displayName,
      'hostPhone': host.phone,
      'hostAvatar': host.avatarUrl,
    }, SetOptions(merge: true));

    if (context.mounted) context.push('/chat/$convId');
  }

  // Construit un UserModel de secours depuis les données dénormalisées des annonces
  UserModel? _fallbackHost(List<ListingModel> listings) {
    if (listings.isEmpty) return null;
    final l = listings.first;
    return UserModel(
      id: hostId,
      email: l.hostEmail,
      name: l.hostName.isNotEmpty ? l.hostName : 'Propriétaire',
      phone: l.hostPhone,
      avatarUrl: l.hostAvatarUrl,
      role: UserRole.host,
      isVerified: l.hostIsVerified,
      favoriteIds: const [],
      createdAt: DateTime.now(),
      businessName: l.hostName,
      businessType: l.hostBusinessType,
      businessAddress: l.hostBusinessAddress,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostAsync = ref.watch(hostByIdProvider(hostId));
    final listingsAsync = ref.watch(hostListingsStreamProvider(hostId));
    final listings = listingsAsync.valueOrNull ?? [];

    final avgRating = listings.isEmpty
        ? 0.0
        : listings.fold<double>(0, (s, l) => s + l.avgRating) / listings.length;
    final totalReviews = listings.fold<int>(0, (s, l) => s + l.reviewCount);

    // Collecte tous les médias (photos + vidéos) de toutes les annonces
    final allMedia = <_MediaItem>[];
    for (final l in listings) {
      if (l.hasVideo && l.videoUrl.isNotEmpty) {
        allMedia.add(_MediaItem(url: l.videoUrl, thumbnail: l.mainImage, isVideo: true));
      }
      for (final url in l.mediaUrls) {
        if (url.isNotEmpty) allMedia.add(_MediaItem(url: url, thumbnail: url, isVideo: false));
      }
    }

    void openMedia(int index) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.93),
        barrierDismissible: true,
        builder: (_) => _MediaViewerDialog(items: allMedia, initialIndex: index),
      );
    }

    // Résolution de l'hôte : Firestore en priorité, sinon données dénormalisées
    final host = hostAsync.valueOrNull ?? _fallbackHost(listings);

    // Encore en chargement et pas de fallback disponible
    if (host == null && hostAsync.isLoading && listings.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Vraiment introuvable
    if (host == null && !hostAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.pop()),
          title: const Text('Profil propriétaire'),
        ),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
              child: const Icon(Icons.person_off_outlined, size: 40, color: AppColors.textHint),
            ),
            const SizedBox(height: 16),
            const Text('Profil indisponible', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Les informations de ce propriétaire\nne sont pas encore disponibles.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            OutlinedButton(onPressed: () => context.pop(), child: const Text('Retour')),
          ]),
        ),
      );
    }

    final displayName = (host?.hasBusiness == true ? host!.businessName : host?.name) ?? 'Propriétaire';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0D47A1),
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _HostHeader(
                displayName: displayName,
                subName: host?.hasBusiness == true ? (host?.name ?? '') : '',
                avatarUrl: host?.avatarUrl ?? '',
                initial: initial,
                businessAddress: host?.businessAddress ?? '',
                isVerified: host?.isVerified ?? false,
              ),
            ),
          ),

          // ── Stats ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(children: [
                _StatItem(value: '${listings.length}', label: 'Annonces', icon: Icons.home_work_rounded, color: const Color(0xFF1565C0)),
                _Vdivider(),
                _StatItem(value: '$totalReviews', label: 'Avis', icon: Icons.reviews_rounded, color: AppColors.primary),
                _Vdivider(),
                _StatItem(
                  value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '—',
                  label: 'Note moy.',
                  icon: Icons.star_rounded,
                  color: AppColors.star,
                ),
              ]),
            ),
          ),

          // ── Infos + Contact ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Badge vérifié
                if (host?.isVerified == true) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.verified_rounded, color: Color(0xFF1565C0), size: 16),
                      SizedBox(width: 8),
                      Text('Entreprise vérifiée', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Type d'entreprise
                if (host?.businessType.isNotEmpty == true) ...[
                  Row(children: [
                    const Icon(Icons.category_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(host!.businessType, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ]),
                  const SizedBox(height: 10),
                ],

                // Adresse
                if (host?.businessAddress.isNotEmpty == true) ...[
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(host!.businessAddress, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))),
                  ]),
                  const SizedBox(height: 10),
                ],

                // Email
                if (host?.email.isNotEmpty == true) ...[
                  Row(children: [
                    const Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(host!.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))),
                  ]),
                  const SizedBox(height: 10),
                ],

                // Phone
                if (host?.phone.isNotEmpty == true) ...[
                  Row(children: [
                    const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(host!.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ]),
                  const SizedBox(height: 10),
                ],

                // Description
                if (host?.businessDescription.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text('À propos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(host!.businessDescription, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),

                // Boutons contact
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openChat(context, ref, host!, displayName),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => showCallOptionsSheet(
                        context,
                        hostId: hostId,
                        hostName: displayName,
                        hostPhone: host?.phone ?? '',
                        hostAvatar: host?.avatarUrl ?? '',
                      ),
                      icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                      label: const Text('Appeler', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ),

          // ── Catalogue médias ─────────────────────────────────────────
          if (allMedia.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.photo_library_rounded, size: 17, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Photos & Vidéos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(10)),
                      child: Text('${allMedia.length}', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: allMedia.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final item = allMedia[i];
                        return GestureDetector(
                          onTap: () => openMedia(i),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(children: [
                              CachedNetworkImage(
                                imageUrl: item.thumbnail,
                                width: 110, height: 110,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(width: 110, height: 110, color: AppColors.surfaceVariant),
                                errorWidget: (_, _, _) => Container(width: 110, height: 110, color: AppColors.surfaceVariant,
                                    child: const Icon(Icons.broken_image_outlined, color: AppColors.textHint)),
                              ),
                              if (item.isVideo)
                                Positioned.fill(child: Container(
                                  color: Colors.black38,
                                  child: const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 34)),
                                )),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ),
            ),

          // ── Séparateur + Titre annonces ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(children: [
                Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
                const SizedBox(width: 12),
                Text('Toutes les offres', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(20)),
                  child: Text('${listings.length}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
              ]),
            ),
          ),

          // ── Grille annonces ─────────────────────────────────────────
          listingsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Erreur: $e')),
            ),
            data: (data) {
              if (data.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.home_outlined, size: 48, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      const Text('Aucune annonce disponible', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                    ]),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ListingCard(
                      listing: data[i],
                      onTap: () => context.push('/listing/${data[i].id}'),
                    ),
                    childCount: data.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _HostHeader extends StatelessWidget {
  final String displayName;
  final String subName;
  final String avatarUrl;
  final String initial;
  final String businessAddress;
  final bool isVerified;

  const _HostHeader({
    required this.displayName,
    required this.subName,
    required this.avatarUrl,
    required this.initial,
    required this.businessAddress,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 20),
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white,
              child: avatarUrl.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: avatarUrl,
                        width: 88, height: 88,
                        fit: BoxFit.cover,
                        errorWidget: (ctx, url, err) => Text(initial,
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                      ),
                    )
                  : Text(initial, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
            ),
          ),
          const SizedBox(height: 12),
          // Nom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: Text(
                  displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, color: Colors.lightBlueAccent, size: 22),
              ],
            ]),
          ),
          // Sous-nom (prénom si entreprise)
          if (subName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
          // Adresse
          if (businessAddress.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.location_on_rounded, color: Colors.white60, size: 13),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    businessAddress,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// ── Widgets utilitaires ─────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _Vdivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 40, color: AppColors.border);
}

// ── Modèle média ───────────────────────────────────────────────────────────

class _MediaItem {
  final String url;
  final String thumbnail;
  final bool isVideo;
  const _MediaItem({required this.url, required this.thumbnail, required this.isVideo});
}

// ── Visionneuse plein écran ─────────────────────────────────────────────────

class _MediaViewerDialog extends StatefulWidget {
  final List<_MediaItem> items;
  final int initialIndex;
  const _MediaViewerDialog({required this.items, required this.initialIndex});

  @override
  State<_MediaViewerDialog> createState() => _MediaViewerDialogState();
}

class _MediaViewerDialogState extends State<_MediaViewerDialog> {
  late final PageController _pageCtrl;
  late int _current;
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _current);
    _initVideo(_current);
  }

  void _initVideo(int index) {
    _videoCtrl?.dispose();
    _videoCtrl = null;
    _videoReady = false;
    final item = widget.items[index];
    if (!item.isVideo) return;
    _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(item.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _videoReady = true);
          _videoCtrl?.play();
        }
      });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_current];
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(children: [
        // ── Contenu swipeable ──
        PageView.builder(
          controller: _pageCtrl,
          itemCount: widget.items.length,
          onPageChanged: (i) => setState(() {
            _current = i;
            _initVideo(i);
          }),
          itemBuilder: (_, i) {
            final m = widget.items[i];
            if (m.isVideo && i == _current) {
              if (_videoReady && _videoCtrl != null) {
                return GestureDetector(
                  onTap: () => _videoCtrl!.value.isPlaying ? _videoCtrl!.pause() : _videoCtrl!.play(),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _videoCtrl!.value.aspectRatio,
                      child: VideoPlayer(_videoCtrl!),
                    ),
                  ),
                );
              }
              return Stack(alignment: Alignment.center, children: [
                if (m.thumbnail.isNotEmpty)
                  CachedNetworkImage(imageUrl: m.thumbnail, fit: BoxFit.contain),
                const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ]);
            }
            return InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: m.url,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  errorWidget: (_, _, _) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
                ),
              ),
            );
          },
        ),

        // ── Bouton fermer ──
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),

        // ── Compteur + indicateur ──
        if (widget.items.length > 1)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 18,
            left: 0, right: 0,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(item.isVideo ? Icons.videocam_rounded : Icons.photo_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text('${_current + 1} / ${widget.items.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.items.length.clamp(0, 10),
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _current ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _current ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}

// ── Carte annonce ───────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;
  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(fit: StackFit.expand, children: [
                listing.mainImage.isNotEmpty
                    ? CachedNetworkImage(imageUrl: listing.mainImage, fit: BoxFit.cover,
                        errorWidget: (ctx, url, err) => Container(color: AppColors.surfaceVariant,
                            child: const Icon(Icons.home_rounded, color: AppColors.textHint, size: 32)))
                    : Container(color: AppColors.surfaceVariant,
                        child: const Icon(Icons.home_rounded, color: AppColors.textHint, size: 32)),
                // Type badge
                Positioned(
                  bottom: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: Text(listing.type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (listing.hasVideo)
                  const Positioned(
                    top: 8, right: 8,
                    child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 22),
                  ),
              ]),
            ),
          ),
          // Infos
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(listing.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
                Row(children: [
                  RatingBarIndicator(
                    rating: listing.avgRating,
                    itemCount: 5, itemSize: 11,
                    itemBuilder: (_, index) => const Icon(Icons.star_rounded, color: AppColors.star),
                  ),
                  const SizedBox(width: 3),
                  Text('${listing.avgRating}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AppUtils.formatPrice(listing.pricePerNight),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const Text('/nuit', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
