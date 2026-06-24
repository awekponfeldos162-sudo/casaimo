import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
});

class HostBookingsScreen extends ConsumerStatefulWidget {
  const HostBookingsScreen({super.key});

  @override
  ConsumerState<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends ConsumerState<HostBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _tabs = ['Toutes', 'En attente', 'Confirmées', 'Terminées'];
  static const _filters = [null, 'pending', 'confirmed', 'completed'];

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
            final filter = _filters[i];
            final bookings = filter == null
                ? allBookings
                : allBookings.where((b) => b.status.name == filter).toList();
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
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _BookingCard(
                booking: bookings[i],
                onConfirm: bookings[i].status == BookingStatus.pending
                    ? () => _updateStatus(bookings[i].id, BookingStatus.confirmed)
                    : null,
                onCancel: bookings[i].status == BookingStatus.pending ||
                        bookings[i].status == BookingStatus.confirmed
                    ? () => _updateStatus(bookings[i].id, BookingStatus.cancelled)
                    : null,
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _updateStatus(String bookingId, BookingStatus status) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'status': status.name});
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _BookingCard({required this.booking, this.onConfirm, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    final statusLabel = _statusLabel(booking.status);

    return GestureDetector(
      onTap: () => context.push('/booking-detail/${booking.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Guest info ──────────────────────────────────────────
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryContainer,
              backgroundImage: booking.guestAvatar.isNotEmpty
                  ? NetworkImage(booking.guestAvatar)
                  : null,
              child: booking.guestAvatar.isEmpty
                  ? Text(
                      booking.guestName.isNotEmpty
                          ? booking.guestName[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                booking.guestName.isNotEmpty ? booking.guestName : 'Client',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              Text(
                '${booking.guests} voyageur${booking.guests > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ),
          ]),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Listing title ───────────────────────────────────────
          Text(
            booking.listingTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // ── Dates ───────────────────────────────────────────────
          Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(child: Text(
              AppUtils.formatDateRange(booking.checkIn, booking.checkOut),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )),
            const Icon(Icons.nights_stay_rounded, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '${booking.nights} nuit${booking.nights > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ]),

          const SizedBox(height: 10),

          // ── Total + link ────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${AppUtils.formatPrice(booking.pricePerNight)} × ${booking.nights} nuits',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                AppUtils.formatPrice(booking.total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  'Voir le détail',
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
              ]),
            ),
          ]),

          // ── Confirm / cancel actions ────────────────────────────
          if (onConfirm != null || onCancel != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(children: [
              if (onConfirm != null)
                Expanded(child: FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Confirmer', style: TextStyle(fontSize: 13)),
                )),
              if (onConfirm != null && onCancel != null) const SizedBox(width: 8),
              if (onCancel != null)
                Expanded(child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Refuser', style: TextStyle(fontSize: 13)),
                )),
            ]),
          ],
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
