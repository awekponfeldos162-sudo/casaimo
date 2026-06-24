import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/presentation/providers/listing_provider.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  final String? listingId;
  const CreateListingScreen({super.key, this.listingId});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  int _step = 0;
  bool _publishing = false;
  bool _loadingExisting = false;

  final _formData = <String, dynamic>{
    'type': 'Appartement',
    'title': '',
    'description': '',
    'address': '',
    'city': '',
    'bedrooms': 1,
    'bathrooms': 1,
    'maxGuests': 2,
    'amenities': <String>[],
    'mediaUrls': <String>[],
    'videoUrl': '',
    'pricePerNight': 0.0,
    'pricePerMonth': 0.0,
    'cleaningFee': 0.0,
    'cancellationPolicy': 'flexible',
  };

  static const _steps = ['Catégorie', 'Infos', 'Médias', 'Équipements', 'Tarification', 'Aperçu'];

  bool get _isEdit => widget.listingId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadExistingListing();
  }

  Future<void> _loadExistingListing() async {
    setState(() => _loadingExisting = true);
    try {
      final listing = await ref.read(listingRepositoryProvider).getById(widget.listingId!);
      if (listing != null && mounted) {
        setState(() {
          _formData['type'] = listing.type;
          _formData['title'] = listing.title;
          _formData['description'] = listing.description;
          _formData['address'] = listing.address;
          _formData['city'] = listing.city;
          _formData['bedrooms'] = listing.bedrooms;
          _formData['bathrooms'] = listing.bathrooms;
          _formData['maxGuests'] = listing.maxGuests;
          _formData['amenities'] = List<String>.from(listing.amenities);
          _formData['mediaUrls'] = List<String>.from(listing.mediaUrls);
          _formData['videoUrl'] = listing.videoUrl;
          _formData['pricePerNight'] = listing.pricePerNight;
          _formData['pricePerMonth'] = listing.pricePerMonth;
          _formData['cleaningFee'] = listing.cleaningFee;
          _formData['cancellationPolicy'] = listing.cancellationPolicy;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier l\'annonce' : 'Nouvelle annonce'),
        leading: _step == 0
            ? BackButton(onPressed: () => context.pop())
            : BackButton(onPressed: () => setState(() => _step--)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / _steps.length,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ),
      body: _loadingExisting ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Étape ${_step + 1} / ${_steps.length} — ', style: Theme.of(context).textTheme.bodySmall),
            Text(_steps[_step], style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary)),
          ]),
        ),
        Expanded(
          child: IndexedStack(
            index: _step,
            children: [
              _StepCategory(
                selected: _formData['type'] as String,
                onSelect: (t) => setState(() => _formData['type'] = t),
              ),
              _StepBasicInfo(data: _formData, onChanged: (k, v) => setState(() => _formData[k] = v)),
              _StepMedia(
                hostId: ref.read(authProvider)?.id ?? '',
                mediaUrls: _formData['mediaUrls'] as List<String>,
                videoUrl: _formData['videoUrl'] as String,
                onAddUrl: (url) => setState(() => (_formData['mediaUrls'] as List<String>).add(url)),
                onRemoveUrl: (url) => setState(() => (_formData['mediaUrls'] as List<String>).remove(url)),
                onVideoChanged: (url) => setState(() => _formData['videoUrl'] = url),
              ),
              _StepAmenities(
                selected: _formData['amenities'] as List<String>,
                onToggle: (a) {
                  setState(() {
                    final list = _formData['amenities'] as List<String>;
                    list.contains(a) ? list.remove(a) : list.add(a);
                  });
                },
              ),
              _StepPricing(data: _formData, onChanged: (k, v) => setState(() => _formData[k] = v)),
              _StepPreview(data: _formData),
            ],
          ),
        ),
      ]),
      bottomNavigationBar: _BottomNav(
        step: _step,
        total: _steps.length,
        publishing: _publishing,
        onNext: () {
          if (_step < _steps.length - 1) {
            setState(() => _step++);
          } else {
            _publish();
          }
        },
      ),
    );
  }

  Future<void> _publish() async {
    final user = ref.read(authProvider);
    if (user == null) return;
    setState(() => _publishing = true);
    try {
      final listing = ListingModel(
        id: '',
        hostId: user.id,
        hostName: user.hasBusiness ? user.businessName : user.name,
        hostAvatarUrl: user.avatarUrl,
        hostPhone: user.phone,
        hostEmail: user.email,
        hostBusinessType: user.businessType,
        hostBusinessAddress: user.businessAddress,
        hostIsVerified: user.isVerified,
        type: _formData['type'] as String,
        title: _formData['title'] as String,
        description: _formData['description'] as String,
        address: _formData['address'] as String,
        city: _formData['city'] as String,
        lat: 0, lng: 0,
        amenities: List<String>.from(_formData['amenities'] as List),
        mediaUrls: List<String>.from(_formData['mediaUrls'] as List),
        videoUrl: _formData['videoUrl'] as String,
        pricePerNight: (_formData['pricePerNight'] as num).toDouble(),
        pricePerMonth: (_formData['pricePerMonth'] as num).toDouble(),
        cleaningFee: (_formData['cleaningFee'] as num).toDouble(),
        serviceFeePercent: 0.12,
        cancellationPolicy: _formData['cancellationPolicy'] as String,
        minStay: 1, maxStay: 30,
        bedrooms: _formData['bedrooms'] as int,
        bathrooms: _formData['bathrooms'] as int,
        maxGuests: _formData['maxGuests'] as int,
        avgRating: 0, reviewCount: 0,
        status: 'published',
        createdAt: DateTime.now(),
      );
      if (_isEdit) {
        await ref.read(listingRepositoryProvider).update(widget.listingId!, listing.toFirestore());
      } else {
        await ref.read(listingRepositoryProvider).create(listing);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Annonce mise à jour !' : 'Annonce publiée !'), backgroundColor: AppColors.success),
        );
        context.go('/host/listings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }
}

// ── Step 0 : Catégorie ─────────────────────────────────────────────────────

class _StepCategory extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _StepCategory({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final icons = AppConstants.listingTypeIcons;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Type de bien', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Choisissez la catégorie qui correspond le mieux à votre offre.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: AppConstants.listingTypes.length,
          itemBuilder: (context, i) {
            final type = AppConstants.listingTypes[i];
            final isSelected = type == selected;
            return GestureDetector(
              onTap: () => onSelect(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryContainer : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icons[type] ?? Icons.home_rounded, size: 32, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                  const SizedBox(height: 8),
                  Text(
                    type,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }
}

// ── Step 1 : Infos de base ────────────────────────────────────────────────

class _StepBasicInfo extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onChanged;
  const _StepBasicInfo({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Informations de base', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        TextFormField(
          initialValue: data['title'] as String,
          decoration: const InputDecoration(labelText: 'Titre de l\'annonce'),
          onChanged: (v) => onChanged('title', v),
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: data['description'] as String,
          decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
          maxLines: 4,
          onChanged: (v) => onChanged('description', v),
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: data['address'] as String,
          decoration: const InputDecoration(labelText: 'Adresse', prefixIcon: Icon(Icons.location_on_outlined)),
          onChanged: (v) => onChanged('address', v),
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: data['city'] as String,
          decoration: const InputDecoration(labelText: 'Ville (ex: Cotonou, Lomé, Abidjan)', prefixIcon: Icon(Icons.location_city_outlined)),
          onChanged: (v) => onChanged('city', v),
        ),
        const SizedBox(height: 20),
        Text('Capacité', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _Counter(label: 'Chambres', value: data['bedrooms'] as int, onChanged: (v) => onChanged('bedrooms', v)),
        const SizedBox(height: 10),
        _Counter(label: 'Salles de bain', value: data['bathrooms'] as int, onChanged: (v) => onChanged('bathrooms', v)),
        const SizedBox(height: 10),
        _Counter(label: 'Voyageurs max', value: data['maxGuests'] as int, onChanged: (v) => onChanged('maxGuests', v)),
      ]),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _Counter({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      Row(children: [
        _Btn(icon: Icons.remove, onTap: value > 1 ? () => onChanged(value - 1) : null),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$value', style: Theme.of(context).textTheme.titleMedium)),
        _Btn(icon: Icons.add, onTap: () => onChanged(value + 1)),
      ]),
    ]);
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Btn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: onTap != null ? AppColors.primary : AppColors.border),
        ),
        child: Icon(icon, size: 16, color: onTap != null ? AppColors.primary : AppColors.textHint),
      ),
    );
  }
}

// ── Step 2 : Médias ───────────────────────────────────────────────────────

class _StepMedia extends StatefulWidget {
  final String hostId;
  final List<String> mediaUrls;
  final String videoUrl;
  final ValueChanged<String> onAddUrl;
  final ValueChanged<String> onRemoveUrl;
  final ValueChanged<String> onVideoChanged;
  const _StepMedia({
    required this.hostId,
    required this.mediaUrls,
    required this.videoUrl,
    required this.onAddUrl,
    required this.onRemoveUrl,
    required this.onVideoChanged,
  });

  @override
  State<_StepMedia> createState() => _StepMediaState();
}

class _StepMediaState extends State<_StepMedia> {
  bool _uploadingPhoto = false;
  bool _uploadingVideo = false;
  double _photoProgress = 0;
  double _videoProgress = 0;
  String? _uploadError;

  Future<void> _pickPhoto() async {
    setState(() { _uploadingPhoto = true; _uploadError = null; _photoProgress = 0; });
    try {
      final url = await StorageService.pickAndUploadImage(
        widget.hostId,
        onProgress: (p) => setState(() => _photoProgress = p),
      );
      if (url != null) widget.onAddUrl(url);
    } catch (e) {
      setState(() => _uploadError = 'Erreur upload photo : $e');
    } finally {
      setState(() { _uploadingPhoto = false; _photoProgress = 0; });
    }
  }

  Future<void> _pickVideo() async {
    setState(() { _uploadingVideo = true; _uploadError = null; _videoProgress = 0; });
    try {
      final url = await StorageService.pickAndUploadVideo(
        widget.hostId,
        onProgress: (p) => setState(() => _videoProgress = p),
      );
      if (url != null) widget.onVideoChanged(url);
    } catch (e) {
      setState(() => _uploadError = 'Erreur upload vidéo : $e');
    } finally {
      setState(() { _uploadingVideo = false; _videoProgress = 0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Photos & Vidéo', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text(
          'Ajoutez au moins 3 photos HD. Une vidéo d\'1 min valorise votre offre.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // ── Photos ────────────────────────────────────────────────
        Row(children: [
          Text('Photos (${widget.mediaUrls.length})', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          if (widget.mediaUrls.isNotEmpty)
            Text('Glissez pour réorganiser', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint)),
        ]),
        const SizedBox(height: 12),

        // Thumbnails
        if (widget.mediaUrls.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.mediaUrls.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.mediaUrls[i],
                      width: 110, height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, url, err) => Container(
                        width: 110, height: 110,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.broken_image_rounded, color: AppColors.textHint),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => widget.onRemoveUrl(widget.mediaUrls[i]),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  if (i == 0)
                    Positioned(
                      bottom: 4, left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                        child: const Text('Principale', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Upload photo button + progress
        if (_uploadingPhoto)
          _UploadProgress(label: 'Upload en cours…', progress: _photoProgress)
        else
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.add_photo_alternate_rounded),
            label: const Text('Ajouter une photo depuis la galerie'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
            ),
          ),
        const SizedBox(height: 28),

        // ── Vidéo ─────────────────────────────────────────────────
        Row(children: [
          Text('Vidéo de présentation', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(6)),
            child: const Text('1 min max', style: TextStyle(color: Color(0xFFE65100), fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        const Text(
          'La vidéo augmente les réservations de 40 %. Sélectionnez une vidéo depuis votre galerie.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),

        if (widget.videoUrl.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              const Expanded(child: Text('Vidéo uploadée avec succès', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
              TextButton(
                onPressed: () => widget.onVideoChanged(''),
                child: const Text('Supprimer', style: TextStyle(color: AppColors.error, fontSize: 12)),
              ),
            ]),
          )
        else if (_uploadingVideo)
          _UploadProgress(label: 'Upload vidéo en cours…', progress: _videoProgress)
        else
          OutlinedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Choisir une vidéo depuis la galerie'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1565C0)),
              foregroundColor: const Color(0xFF1565C0),
            ),
          ),

        // Error message
        if (_uploadError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_uploadError!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _UploadProgress extends StatelessWidget {
  final String label;
  final double progress;
  const _UploadProgress({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary))),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('${(progress * 100).toInt()}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ]),
    );
  }
}

// ── Step 3 : Équipements ──────────────────────────────────────────────────

class _StepAmenities extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<String> onToggle;
  const _StepAmenities({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Équipements', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('${selected.length} sélectionné${selected.length > 1 ? 's' : ''}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: AppConstants.amenities.map((a) {
          final isSelected = selected.contains(a);
          return GestureDetector(
            onTap: () => onToggle(a),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryContainer : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, size: 16, color: isSelected ? AppColors.primary : AppColors.textHint),
                const SizedBox(width: 6),
                Text(a, style: TextStyle(fontSize: 13, color: isSelected ? AppColors.primary : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
              ]),
            ),
          );
        }).toList()),
      ]),
    );
  }
}

// ── Step 4 : Tarification ─────────────────────────────────────────────────

class _StepPricing extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onChanged;
  const _StepPricing({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tarification', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        TextFormField(
          initialValue: data['pricePerNight'] == 0.0 ? '' : '${data['pricePerNight']}',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Prix par nuit (FCFA)', prefixIcon: Icon(Icons.nights_stay_outlined)),
          onChanged: (v) => onChanged('pricePerNight', double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: data['pricePerMonth'] == 0.0 ? '' : '${data['pricePerMonth']}',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Prix par mois (FCFA) — optionnel',
            prefixIcon: Icon(Icons.calendar_month_outlined),
            helperText: 'Laissez vide si vous ne proposez pas de tarif mensuel',
          ),
          onChanged: (v) => onChanged('pricePerMonth', double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: data['cleaningFee'] == 0.0 ? '' : '${data['cleaningFee']}',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Frais de ménage (FCFA)', prefixIcon: Icon(Icons.cleaning_services_rounded)),
          onChanged: (v) => onChanged('cleaningFee', double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 24),
        Text('Politique d\'annulation', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...() {
          const labels = {
            'flexible': 'Flexible — Remboursement 24h avant',
            'moderate': 'Modérée — Remboursement 5 jours avant',
            'strict': 'Stricte — Remboursement 14 jours avant',
          };
          final current = data['cancellationPolicy'] as String? ?? 'flexible';
          return ['flexible', 'moderate', 'strict'].map((p) {
            final isSelected = current == p;
            return GestureDetector(
              onTap: () => onChanged('cancellationPolicy', p),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryContainer : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1),
                ),
                child: Row(children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? AppColors.primary : AppColors.textHint,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    labels[p] ?? p,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  )),
                ]),
              ),
            );
          }).toList();
        }(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Des frais de service de 12 % sont ajoutés automatiquement pour les voyageurs.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary))),
          ]),
        ),
      ]),
    );
  }
}

// ── Step 5 : Aperçu ───────────────────────────────────────────────────────

class _StepPreview extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StepPreview({required this.data});

  @override
  Widget build(BuildContext context) {
    final mediaUrls = data['mediaUrls'] as List<String>;
    final amenities = data['amenities'] as List<String>;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Aperçu de l\'annonce', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text('Vérifiez avant de publier.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        // Photo preview
        if (mediaUrls.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(mediaUrls.first, height: 180, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (ctx, url, err) => Container(height: 180, color: AppColors.surfaceVariant),
            ),
          ),
        const SizedBox(height: 16),

        _PreviewRow(label: 'Catégorie', value: data['type'] as String),
        _PreviewRow(label: 'Titre', value: (data['title'] as String).isEmpty ? 'Non renseigné' : data['title'] as String),
        _PreviewRow(label: 'Ville', value: (data['city'] as String).isEmpty ? 'Non renseigné' : data['city'] as String),
        _PreviewRow(label: 'Chambres', value: '${data['bedrooms']}'),
        _PreviewRow(label: 'Salles de bain', value: '${data['bathrooms']}'),
        _PreviewRow(label: 'Voyageurs max', value: '${data['maxGuests']}'),
        _PreviewRow(label: 'Prix / nuit', value: data['pricePerNight'] == 0.0 ? 'Non renseigné' : '${data['pricePerNight']} FCFA'),
        if ((data['pricePerMonth'] as num) > 0)
          _PreviewRow(label: 'Prix / mois', value: '${data['pricePerMonth']} FCFA'),
        _PreviewRow(label: 'Photos', value: '${mediaUrls.length} ajoutée${mediaUrls.length > 1 ? 's' : ''}'),
        _PreviewRow(label: 'Vidéo', value: (data['videoUrl'] as String).isNotEmpty ? 'Oui' : 'Non'),
        _PreviewRow(label: 'Équipements', value: '${amenities.length} sélectionné${amenities.length > 1 ? 's' : ''}'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('En publiant, votre annonce sera visible par tous les voyageurs.', style: TextStyle(color: AppColors.primary, fontSize: 13))),
          ]),
        ),
      ]),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label, value;
  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.titleSmall)),
      ]),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int step, total;
  final bool publishing;
  final VoidCallback onNext;
  const _BottomNav({required this.step, required this.total, required this.publishing, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: ElevatedButton(
        onPressed: publishing ? null : onNext,
        child: publishing
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(step == total - 1 ? 'Publier l\'annonce' : 'Continuer'),
      ),
    );
  }
}
