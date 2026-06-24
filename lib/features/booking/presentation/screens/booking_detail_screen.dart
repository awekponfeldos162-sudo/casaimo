import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../data/models/booking_model.dart';

final bookingDetailProvider = FutureProvider.family<BookingModel?, String>((ref, id) async {
  final doc = await FirebaseFirestore.instance.collection('bookings').doc(id).get();
  if (!doc.exists) return null;
  return BookingModel.fromFirestore(doc);
});

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookingDetailProvider(bookingId));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Erreur: $e'))),
      data: (booking) {
        if (booking == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Réservation')),
            body: const Center(child: Text('Réservation introuvable')),
          );
        }
        return _DetailView(booking: booking);
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  final BookingModel booking;
  const _DetailView({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    final statusLabel = _statusLabel(booking.status);
    final sub = booking.pricePerNight * booking.nights;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            title: const Text(
              'Détails réservation',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _GreenHeader(booking: booking),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Guest / client card ─────────────────────────────────
                _Card(
                  child: Row(children: [
                    _GuestAvatar(name: booking.guestName, url: booking.guestAvatar),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        booking.guestName.isNotEmpty ? booking.guestName : 'Client',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${AppUtils.formatDate(booking.checkIn)} – ${AppUtils.formatDate(booking.checkOut)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ])),
                    _StatusBadge(label: statusLabel, color: statusColor),
                  ]),
                ),

                const SizedBox(height: 12),

                // ── Listing card ────────────────────────────────────────
                _Card(
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: booking.listingImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: booking.listingImage,
                              width: 72, height: 72, fit: BoxFit.cover,
                              errorWidget: (_, _, _) => _ImgPlaceholder(),
                            )
                          : _ImgPlaceholder(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        booking.listingTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 12, children: [
                        _MiniTag(icon: Icons.people_rounded, label: '${booking.guests} voyageur${booking.guests > 1 ? 's' : ''}'),
                        _MiniTag(icon: Icons.nights_stay_rounded, label: '${booking.nights} nuit${booking.nights > 1 ? 's' : ''}'),
                      ]),
                    ])),
                  ]),
                ),

                const SizedBox(height: 12),

                // ── Price breakdown ─────────────────────────────────────
                _Card(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Détail du prix', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ]),
                    const SizedBox(height: 14),
                    _PriceRow(
                      label: '${AppUtils.formatPrice(booking.pricePerNight)} × ${booking.nights} nuit${booking.nights > 1 ? 's' : ''}',
                      value: AppUtils.formatPrice(sub),
                    ),
                    const SizedBox(height: 8),
                    _PriceRow(label: 'Frais de ménage', value: AppUtils.formatPrice(booking.cleaningFee)),
                    const SizedBox(height: 8),
                    _PriceRow(label: 'Frais de service', value: AppUtils.formatPrice(booking.serviceFee)),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text(
                        AppUtils.formatPrice(booking.total),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ]),
                  ]),
                ),

                const SizedBox(height: 12),

                // ── Payment method ──────────────────────────────────────
                _Card(
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _paymentColor(_paymentLabel(booking.paymentMethod)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _paymentIcon(booking.paymentMethod),
                        color: _paymentColor(_paymentLabel(booking.paymentMethod)),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Moyen de paiement', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        _paymentLabel(booking.paymentMethod),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
                        SizedBox(width: 4),
                        Text('Payé', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                    ),
                  ]),
                ),

                const SizedBox(height: 12),

                // ── QR / Booking reference ──────────────────────────────
                _Card(
                  child: Column(children: [
                    const Text('Référence de réservation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 160, height: 160,
                        child: CustomPaint(painter: _QrPainter(seed: booking.id)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${booking.id.substring(0, booking.id.length.clamp(0, 10)).toUpperCase()}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Réservé le ${AppUtils.formatDate(booking.createdAt)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── Actions ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Télécharger le reçu'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home_rounded, size: 18),
                    label: const Text("Retour à l'accueil"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
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

  String _paymentLabel(String method) {
    if (method == 'card_visa') return 'Visa / Mastercard';
    if (method.contains('mtn')) return 'MTN Mobile Money';
    if (method.contains('orange')) return 'Orange Money';
    if (method.contains('moov')) return 'Moov Money';
    if (method.contains('wave')) return 'Wave';
    return method;
  }

  IconData _paymentIcon(String method) {
    if (method == 'card_visa') return Icons.credit_card_rounded;
    return Icons.phone_android_rounded;
  }

  Color _paymentColor(String label) {
    if (label.contains('Visa')) return const Color(0xFF1A1F71);
    if (label.contains('MTN')) return const Color(0xFFFFCC00);
    if (label.contains('Orange')) return const Color(0xFFFF6600);
    if (label.contains('Wave')) return const Color(0xFF00B4D8);
    return AppColors.primary;
  }
}

// ── Header widget ──────────────────────────────────────────────────────────────
class _GreenHeader extends StatelessWidget {
  final BookingModel booking;
  const _GreenHeader({required this.booking});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(height: 44),
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 10),
        const Text(
          'Réservation confirmée',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '${booking.nights} nuit${booking.nights > 1 ? 's' : ''} · ${AppUtils.formatPrice(booking.total)}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
        ),
      ]),
    ),
  );
}

// ── Small reusable widgets ─────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
  );
}

class _GuestAvatar extends StatelessWidget {
  final String name, url;
  const _GuestAvatar({required this.name, required this.url});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 26,
    backgroundColor: AppColors.primaryContainer,
    backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
    child: url.isEmpty
        ? Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'G',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
          )
        : null,
  );
}

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: AppColors.textSecondary),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
  ]);
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
  ]);
}

class _ImgPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 72, height: 72,
    color: AppColors.surfaceVariant,
    child: const Icon(Icons.home_rounded, color: AppColors.textHint),
  );
}

// ── QR code painter ────────────────────────────────────────────────────────────
class _QrPainter extends CustomPainter {
  final String seed;
  const _QrPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = Colors.black87;
    final light = Paint()..color = Colors.white;
    const cells = 21;
    final cs = size.width / cells;

    // White background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), light);

    // Corner finder patterns (QR-style)
    void drawFinder(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, cs * 7, cs * 7), dark);
      canvas.drawRect(Rect.fromLTWH(x + cs, y + cs, cs * 5, cs * 5), light);
      canvas.drawRect(Rect.fromLTWH(x + cs * 2, y + cs * 2, cs * 3, cs * 3), dark);
    }

    drawFinder(0, 0);
    drawFinder((cells - 7) * cs, 0);
    drawFinder(0, (cells - 7) * cs);

    // Data cells from seed
    final bytes = seed.isNotEmpty ? seed.codeUnits : [0];
    for (int row = 0; row < cells; row++) {
      for (int col = 0; col < cells; col++) {
        // Skip finder pattern zones
        if (row < 8 && col < 8) continue;
        if (row < 8 && col >= cells - 8) continue;
        if (row >= cells - 8 && col < 8) continue;

        final idx = (row * cells + col) % bytes.length;
        final bit = (bytes[idx] >> ((row + col) % 8)) & 1;
        if (bit == 1) {
          canvas.drawRect(
            Rect.fromLTWH(col * cs + 0.5, row * cs + 0.5, cs - 1, cs - 1),
            dark,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.seed != seed;
}
