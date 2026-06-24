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
      .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
});

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBookings = ref.watch(bookingHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes réservations')),
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
                itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
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
    final statusLabel = _statusLabel(booking.status);

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

          // Top: thumbnail + info
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
                  // Title + status badge
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
                  // Dates
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Expanded(child: Text(
                      AppUtils.formatDateRange(booking.checkIn, booking.checkOut),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    )),
                  ]),
                  const SizedBox(height: 4),
                  // Nights + guests
                  Row(children: [
                    const Icon(Icons.nights_stay_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      '${booking.nights} nuit${booking.nights > 1 ? 's' : ''} · ${booking.guests} voyageur${booking.guests > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ]),
                ]),
              ),
            ),
          ]),

          // Bottom: total + ref + arrow
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
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

  Color _statusColor(BookingStatus s) => {
    BookingStatus.confirmed: AppColors.success,
    BookingStatus.pending: AppColors.warning,
    BookingStatus.cancelled: AppColors.error,
    BookingStatus.active: AppColors.primary,
    BookingStatus.completed: AppColors.textSecondary,
  }[s] ?? AppColors.textSecondary;

  String _statusLabel(BookingStatus s) => {
    BookingStatus.confirmed: 'Confirmé',
    BookingStatus.pending: 'En attente',
    BookingStatus.cancelled: 'Annulé',
    BookingStatus.active: 'En cours',
    BookingStatus.completed: 'Terminé',
  }[s] ?? '';
}

class _ImgPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 90, height: 100,
    color: AppColors.surfaceVariant,
    child: const Icon(Icons.home_rounded, color: AppColors.textHint, size: 28),
  );
}
