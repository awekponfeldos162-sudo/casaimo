import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/presentation/providers/listing_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String listingId;
  const BookingScreen({super.key, required this.listingId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _step = 0; // 0 = dates/guests, 1 = recap + paiement
  DateTime? _checkIn;
  DateTime? _checkOut;
  DateTime _focusedDay = DateTime.now(); // obligatoire pour TableCalendar
  int _guests = 1;
  bool _loading = false;
  int _photoIndex = 0;

  int get _nights =>
      (_checkIn != null && _checkOut != null) ? _checkOut!.difference(_checkIn!).inDays : 0;

  double _sub(ListingModel l) => l.pricePerNight * _nights;
  double _svc(ListingModel l) => _sub(l) * l.serviceFeePercent;
  double _tot(ListingModel l) => _sub(l) + l.cleaningFee + _svc(l);

  @override
  Widget build(BuildContext context) {
    final asyncListing = ref.watch(listingByIdProvider(widget.listingId));
    return asyncListing.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Erreur: $e'))),
      data: (listing) {
        if (listing == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Bien introuvable')));
        }
        return _step == 0 ? _step0(context, listing) : _step1(context, listing);
      },
    );
  }

  // ── STEP 0 — Dates & Voyageurs ─────────────────────────────────────────────
  Widget _step0(BuildContext context, ListingModel listing) {
    final ready = _checkIn != null && _checkOut != null && _nights > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Photo carousel AppBar
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.black,
            leading: _CircleBtn(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Réservation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                Text('Étape 1/2', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
              ],
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _PhotoCarousel(
                urls: listing.mediaUrls,
                index: _photoIndex,
                onChanged: (i) => setState(() => _photoIndex = i),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Photo dots
              if (listing.mediaUrls.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(listing.mediaUrls.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _photoIndex ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _photoIndex ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                  ),
                ),

              const SizedBox(height: 14),

              // Fiche logement
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      _Chip(label: listing.type, color: AppColors.primary),
                      const SizedBox(width: 8),
                      if (listing.city.isNotEmpty)
                        Row(children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(listing.city, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ]),
                    ]),
                    const SizedBox(height: 8),
                    Text(listing.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.2)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 14, runSpacing: 6, children: [
                      if (listing.bedrooms > 0) _SpecTag(icon: Icons.bed_rounded, label: '${listing.bedrooms} ch.'),
                      if (listing.bathrooms > 0) _SpecTag(icon: Icons.shower_rounded, label: '${listing.bathrooms} sdb'),
                      _SpecTag(icon: Icons.people_rounded, label: 'Max ${listing.maxGuests}'),
                    ]),
                    const Divider(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(AppUtils.formatPrice(listing.pricePerNight),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                        const Text('/nuit', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                      if (_nights > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(20)),
                          child: Text('$_nights nuit${_nights > 1 ? 's' : ''}',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                    ]),
                  ]),
                ),
              ),

              const SizedBox(height: 20),

              // Titre dates
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Choisissez vos dates',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 12),

              // Sélection dates chips
              if (_checkIn != null || _checkOut != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(children: [
                        const Text('Arrivée', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 3),
                        Text(
                          _checkIn != null ? AppUtils.formatDate(_checkIn!) : '—',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
                        ),
                      ])),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                      Expanded(child: Column(children: [
                        const Text('Départ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 3),
                        Text(
                          _checkOut != null ? AppUtils.formatDate(_checkOut!) : '—',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
                        ),
                      ])),
                    ]),
                  ),
                ),

              // Calendrier
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  rangeStartDay: _checkIn,
                  rangeEndDay: _checkOut,
                  rangeSelectionMode: RangeSelectionMode.enforced,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  onPageChanged: (day) => setState(() => _focusedDay = day),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  calendarStyle: CalendarStyle(
                    rangeHighlightColor: AppColors.primaryContainer,
                    rangeStartDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    rangeEndDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.3), shape: BoxShape.circle),
                    withinRangeTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    outsideDaysVisible: false,
                    weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
                  ),
                  onRangeSelected: (start, end, focusedDay) => setState(() {
                    _checkIn = start;
                    _checkOut = end;
                    _focusedDay = focusedDay;
                  }),
                ),
              ),

              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider()),

              // Voyageurs
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.people_rounded, size: 22, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Voyageurs', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('Max ${listing.maxGuests} personnes',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ])),
                    _StepperBtn(icon: Icons.remove, enabled: _guests > 1, onTap: () => setState(() => _guests--)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text('$_guests', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                    _StepperBtn(icon: Icons.add, enabled: _guests < listing.maxGuests, onTap: () => setState(() => _guests++)),
                  ]),
                ),
              ),

              const SizedBox(height: 120),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        label: 'Continuer',
        enabled: ready,
        loading: false,
        priceLabel: ready
            ? '${AppUtils.formatPrice(_tot(listing))} · $_nights nuit${_nights > 1 ? 's' : ''}'
            : '${AppUtils.formatPrice(listing.pricePerNight)} / nuit',
        sublabel: ready ? '$_nights nuit${_nights > 1 ? 's' : ''} · $_guests voyageur${_guests > 1 ? 's' : ''}' : 'Sélectionnez des dates',
        onTap: ready ? () => setState(() => _step = 1) : null,
      ),
    );
  }

  // ── STEP 1 — Récapitulatif & Paiement ──────────────────────────────────────
  Widget _step1(BuildContext context, ListingModel listing) {
    final sub = _sub(listing);
    final svc = _svc(listing);
    final tot = _tot(listing);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => setState(() => _step = 0),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('Récapitulatif', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 16)),
          Text('Étape 2/2', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [

          // Fiche logement compacte
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: listing.mainImage.isNotEmpty
                    ? CachedNetworkImage(imageUrl: listing.mainImage, width: 78, height: 78, fit: BoxFit.cover,
                        errorWidget: (ctx, url, err) => Container(width: 78, height: 78, color: AppColors.surfaceVariant,
                            child: const Icon(Icons.home_rounded, color: AppColors.textHint)))
                    : Container(width: 78, height: 78, color: AppColors.surfaceVariant,
                        child: const Icon(Icons.home_rounded, color: AppColors.textHint)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(listing.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                if (listing.city.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 2),
                    Text(listing.city, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                const SizedBox(height: 6),
                _Chip(label: listing.type, color: AppColors.primary),
              ])),
            ]),
          ),

          const SizedBox(height: 12),

          // Dates & voyageurs
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                label: 'Dates',
                value: '${AppUtils.formatDate(_checkIn!)} → ${AppUtils.formatDate(_checkOut!)}',
              ),
              const Divider(height: 20),
              _InfoRow(icon: Icons.nights_stay_rounded, label: 'Durée', value: '$_nights nuit${_nights > 1 ? 's' : ''}'),
              const Divider(height: 20),
              _InfoRow(icon: Icons.people_rounded, label: 'Voyageurs', value: '$_guests adulte${_guests > 1 ? 's' : ''}'),
            ]),
          ),

          const SizedBox(height: 12),

          // Détail du prix
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Détail du prix', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
              const SizedBox(height: 14),
              _PriceRow(label: '${AppUtils.formatPrice(listing.pricePerNight)} × $_nights nuits', value: AppUtils.formatPrice(sub)),
              const SizedBox(height: 8),
              _PriceRow(label: 'Frais de ménage', value: AppUtils.formatPrice(listing.cleaningFee)),
              const SizedBox(height: 8),
              _PriceRow(
                label: 'Frais de service (${(listing.serviceFeePercent * 100).toInt()}%)',
                value: AppUtils.formatPrice(svc),
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
              _PriceRow(label: 'Total', value: AppUtils.formatPrice(tot), bold: true),
            ]),
          ),

          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        label: 'Confirmer la réservation',
        enabled: true,
        loading: _loading,
        priceLabel: AppUtils.formatPrice(tot),
        sublabel: 'Total toutes charges comprises',
        onTap: () => _confirm(listing),
      ),
    );
  }

  Future<void> _confirm(ListingModel listing) async {
    setState(() => _loading = true);
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) { if (mounted) context.go('/login'); return; }

      // Rafraîchit le token pour garantir que Firestore reçoit request.auth valide
      await firebaseUser.getIdToken(true);

      final uid = firebaseUser.uid;
      final fs = FirebaseFirestore.instance;

      final userDoc = await fs.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      final sub = listing.pricePerNight * _nights;
      final svc = (sub * listing.serviceFeePercent).roundToDouble();
      final total = sub + listing.cleaningFee + svc;

      final bookingRef = fs.collection('bookings').doc();

      // Étape 1 : créer le booking
      await bookingRef.set({
        'listingId':       listing.id,
        'listingTitle':    listing.title,
        'listingImage':    listing.mediaUrls.isNotEmpty ? listing.mediaUrls.first : '',
        'guestId':         uid,
        'guestName':       userData['name'] ?? '',
        'guestAvatar':     userData['avatarUrl'] ?? '',
        'hostId':          listing.hostId,
        'hostName':        listing.hostName,
        'checkIn':         Timestamp.fromDate(_checkIn!),
        'checkOut':        Timestamp.fromDate(_checkOut!),
        'guests':          _guests,
        'pricePerNight':   listing.pricePerNight,
        'cleaningFee':     listing.cleaningFee,
        'serviceFee':      svc,
        'total':           total,
        'status':          'pending_approval',
        'qrToken':         null,
        'rejectionReason': null,
        'createdAt':       FieldValue.serverTimestamp(),
        'updatedAt':       FieldValue.serverTimestamp(),
      });

      // Étape 2 : notifier l'hôte (la règle vérifie que bookingId.guestId == uid)
      await fs.collection('notifications').add({
        'userId':    listing.hostId,
        'type':      'new_booking',
        'title':     'Nouvelle demande de réservation',
        'body':      '${userData['name'] ?? 'Un voyageur'} souhaite réserver "${listing.title}"',
        'bookingId': bookingRef.id,
        'listingId': listing.id,
        'read':      false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) context.go('/booking-confirmation/${bookingRef.id}');
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('[${e.code}] ${e.message ?? 'Erreur Firebase'}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Photo carousel ─────────────────────────────────────────────────────────────
class _PhotoCarousel extends StatelessWidget {
  final List<String> urls;
  final int index;
  final ValueChanged<int> onChanged;
  const _PhotoCarousel({required this.urls, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return Container(color: AppColors.surfaceVariant, child: const Icon(Icons.home_rounded, size: 80, color: AppColors.textHint));
    }
    return PageView.builder(
      itemCount: urls.length,
      onPageChanged: onChanged,
      itemBuilder: (ctx, i) => CachedNetworkImage(
        imageUrl: urls[i],
        fit: BoxFit.cover,
        errorWidget: (ctx, url, err) => Container(color: AppColors.surfaceVariant),
      ),
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _SpecTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: AppColors.textSecondary),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
  ]);
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepperBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: enabled ? AppColors.primary : AppColors.border, width: 1.5),
        color: enabled ? AppColors.primaryContainer : Colors.transparent,
      ),
      child: Icon(icon, size: 18, color: enabled ? AppColors.primary : AppColors.textHint),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: AppColors.textSecondary),
    const SizedBox(width: 10),
    Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    const Spacer(),
    Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
  ]);
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _PriceRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: bold ? Colors.black87 : AppColors.textSecondary)),
    Text(value, style: TextStyle(fontSize: bold ? 17 : 13, fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: bold ? AppColors.primary : Colors.black87)),
  ]);
}


class _BottomBar extends StatelessWidget {
  final String label, priceLabel, sublabel;
  final bool enabled, loading;
  final VoidCallback? onTap;
  const _BottomBar({required this.label, required this.enabled, required this.loading, required this.priceLabel, required this.sublabel, this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: const Border(top: BorderSide(color: AppColors.border)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -3))],
    ),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(priceLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
        Text(sublabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
      const SizedBox(width: 16),
      Expanded(
        child: ElevatedButton(
          onPressed: enabled && !loading ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.border,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ),
    ]),
  );
}
