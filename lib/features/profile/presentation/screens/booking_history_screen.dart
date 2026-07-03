import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/layout/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../booking/data/models/booking_model.dart';

final bookingHistoryProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('bookings')
      .where('guestId', isEqualTo: user.id)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map(BookingModel.fromFirestore)
          .where((b) => !b.hiddenByGuest)
          .toList());
});

bool _isDeletable(BookingStatus s) =>
    s == BookingStatus.completed ||
    s == BookingStatus.rejected ||
    s == BookingStatus.cancelled;

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBookings = ref.watch(bookingHistoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes réservations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: asyncBookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (bookings) => bookings.isEmpty
            ? const EmptyState(
                icon: Icons.calendar_today_rounded,
                title: 'Aucune réservation',
                subtitle: 'Vos réservations apparaîtront ici.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                itemBuilder: (ctx, i) {
                  final booking = bookings[i];
                  final card = _BookingCard(booking: booking);
                  if (!_isDeletable(booking.status)) return card;

                  return Dismissible(
                    key: ValueKey(booking.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => showDialog<bool>(
                      context: ctx,
                      builder: (dlg) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Supprimer ?', style: TextStyle(fontWeight: FontWeight.w700)),
                        content: const Text('Cette réservation sera retirée de votre historique. Cette action est irréversible.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dlg, false), child: const Text('Annuler')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(dlg, true),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    ),
                    onDismissed: (_) => FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(booking.id)
                        .update({'hiddenByGuest': true}),
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                          SizedBox(height: 4),
                          Text('Supprimer', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    child: card,
                  );
                },
              ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    final statusLabel = booking.status.label;

    return GestureDetector(
      onTap: () => context.push('/booking-detail/${booking.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: booking.listingImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: booking.listingImage,
                      width: 90, height: 100, fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _ImgPlaceholder(),
                    )
                  : _ImgPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text(
                      booking.listingTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.2),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Expanded(child: Text(
                      AppUtils.formatDateRange(booking.checkIn, booking.checkOut),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    )),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.nights_stay_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      '${booking.nights} nuit${booking.nights > 1 ? 's' : ''} · ${booking.guests} voyageur${booking.guests > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ]),
                  if (_isDeletable(booking.status)) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.swipe_left_rounded, size: 11, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text('Glisser pour supprimer', style: TextStyle(fontSize: 10, color: AppColors.textHint.withValues(alpha: 0.7))),
                    ]),
                  ],
                ]),
              ),
            ),
          ]),

          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  AppUtils.formatPrice(booking.total),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
                Text(
                  '#${booking.id.substring(0, booking.id.length.clamp(0, 8)).toUpperCase()}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1),
                ),
              ]),
              const Row(children: [
                Text('Voir le détail', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Color _statusColor(BookingStatus s) => switch (s) {
    BookingStatus.pendingApproval => AppColors.warning,
    BookingStatus.confirmed       => AppColors.success,
    BookingStatus.rejected        => AppColors.error,
    BookingStatus.checkedIn       => AppColors.primary,
    BookingStatus.completed       => AppColors.textSecondary,
    BookingStatus.cancelled       => AppColors.error,
    BookingStatus.active          => AppColors.primary,
  };
}

class _ImgPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 90, height: 100,
    color: AppColors.surfaceVariant,
    child: const Icon(Icons.home_rounded, color: AppColors.textHint, size: 28),
  );
}
