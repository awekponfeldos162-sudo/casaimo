import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/layout/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../booking/data/models/booking_model.dart';

final _hostBookingsStreamProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('bookings')
      .where('hostId', isEqualTo: user.id)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map(BookingModel.fromFirestore)
          .where((b) => !b.hiddenByHost)
          .toList());
});

bool _isHostDeletable(BookingStatus s) =>
    s == BookingStatus.completed ||
    s == BookingStatus.rejected ||
    s == BookingStatus.cancelled;

class HostBookingsScreen extends ConsumerStatefulWidget {
  const HostBookingsScreen({super.key});

  @override
  ConsumerState<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends ConsumerState<HostBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _tabs = ['Toutes', 'En attente', 'Confirmées', 'Terminées'];
  static const _statusFilters = <BookingStatus?>[null, BookingStatus.pendingApproval, BookingStatus.confirmed, BookingStatus.completed];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncBookings = ref.watch(_hostBookingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservations'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: asyncBookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (allBookings) => TabBarView(
          controller: _tabCtrl,
          children: List.generate(_tabs.length, (i) {
            final filter = _statusFilters[i];
            final bookings = filter == null
                ? allBookings
                : allBookings.where((b) => b.status == filter).toList();
            if (bookings.isEmpty) {
              return const EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'Aucune réservation',
                subtitle: 'Les réservations de vos biens apparaîtront ici.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final booking = bookings[i];
                final card = _BookingCard(
                  booking: booking,
                  onConfirm: booking.status == BookingStatus.pendingApproval
                      ? () => _approve(booking.id)
                      : null,
                  onCancel: booking.status == BookingStatus.pendingApproval
                      ? () => _reject(booking.id)
                      : null,
                );
                if (!_isHostDeletable(booking.status)) return card;

                return Dismissible(
                  key: ValueKey(booking.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => showDialog<bool>(
                    context: ctx,
                    builder: (dlg) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Archiver ?', style: TextStyle(fontWeight: FontWeight.w700)),
                      content: const Text('Cette réservation sera retirée de votre liste. Cette action est irréversible.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dlg, false), child: const Text('Annuler')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: () => Navigator.pop(dlg, true),
                          child: const Text('Archiver'),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (_) => FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(booking.id)
                      .update({'hiddenByHost': true}),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.archive_rounded, color: Colors.white, size: 28),
                        SizedBox(height: 4),
                        Text('Archiver', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  child: card,
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Future<void> _approve(String bookingId) async {
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) { _snack('Non authentifié', error: true); return; }

      final fs = FirebaseFirestore.instance;
      final bookingRef = fs.collection('bookings').doc(bookingId);

      final bookingDoc = await bookingRef.get();
      if (!bookingDoc.exists) { _snack('Réservation introuvable', error: true); return; }
      final data = bookingDoc.data()!;

      // Step 1 : update booking (hostId == uid → rule passes)
      await bookingRef.update({
        'status': 'confirmed',
        'qrToken': bookingId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Step 2 : notify guest (rule verifies booking.hostId == request.auth.uid)
      await fs.collection('notifications').add({
        'userId': data['guestId'],
        'type': 'booking_confirmed',
        'title': '✅ Réservation confirmée !',
        'body': 'Votre réservation pour "${data['listingTitle']}" a été acceptée. Votre ticket QR est prêt.',
        'bookingId': bookingId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _snack('Réservation acceptée ✅');
    } on FirebaseException catch (e) {
      _snack('[${e.code}] ${e.message ?? 'Erreur Firebase'}', error: true);
    } catch (e) {
      _snack('Erreur: $e', error: true);
    }
  }

  Future<void> _reject(String bookingId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Motif du refus', style: TextStyle(fontWeight: FontWeight.w700)),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: 'Optionnel — laissez vide si pas de motif',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Refuser'),
            ),
          ],
        );
      },
    );
    if (reason == null) return; // annulé

    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) { _snack('Non authentifié', error: true); return; }

      final fs = FirebaseFirestore.instance;
      final bookingRef = fs.collection('bookings').doc(bookingId);

      final bookingDoc = await bookingRef.get();
      if (!bookingDoc.exists) { _snack('Réservation introuvable', error: true); return; }
      final data = bookingDoc.data()!;

      // Step 1 : update booking
      await bookingRef.update({
        'status': 'rejected',
        'rejectionReason': reason.isEmpty ? 'Aucune raison fournie' : reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Step 2 : notify guest
      await fs.collection('notifications').add({
        'userId': data['guestId'],
        'type': 'booking_rejected',
        'title': 'Réservation refusée',
        'body': 'Votre réservation pour "${data['listingTitle']}" n\'a pas pu être acceptée.',
        'bookingId': bookingId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _snack('Réservation refusée');
    } on FirebaseException catch (e) {
      _snack('[${e.code}] ${e.message ?? 'Erreur Firebase'}', error: true);
    } catch (e) {
      _snack('Erreur: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.primary,
    ));
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _BookingCard({required this.booking, this.onConfirm, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (booking.status) {
      BookingStatus.pendingApproval => AppColors.warning,
      BookingStatus.confirmed       => AppColors.success,
      BookingStatus.rejected        => AppColors.error,
      BookingStatus.checkedIn       => AppColors.primary,
      BookingStatus.active          => AppColors.primary,
      BookingStatus.completed       => AppColors.textSecondary,
      BookingStatus.cancelled       => AppColors.error,
    };

    final statusLabel = booking.status.label;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.listingTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                AppUtils.formatDateRange(booking.checkIn, booking.checkOut),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                AppUtils.formatPrice(booking.total),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('#${booking.id.substring(0, 8)}', style: Theme.of(context).textTheme.labelSmall),
          if (onConfirm != null || onCancel != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (onConfirm != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: onConfirm,
                      child: const Text('Confirmer'),
                    ),
                  ),
                if (onConfirm != null && onCancel != null) const SizedBox(width: 8),
                if (onCancel != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Refuser'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
