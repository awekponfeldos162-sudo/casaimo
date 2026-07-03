import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../data/models/booking_model.dart';

class BookingTicketScreen extends StatelessWidget {
  final String bookingId;
  const BookingTicketScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final booking = BookingModel.fromFirestore(snap.data!);
        return _TicketBody(booking: booking);
      },
    );
  }
}

class _TicketBody extends StatelessWidget {
  final BookingModel booking;
  const _TicketBody({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mon ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.white),
            tooltip: 'Copier N° réservation',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: booking.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('N° copié'), duration: Duration(seconds: 2)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(children: [
            // Ticket card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Column(children: [

                // Header vert du ticket
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.villa_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text('CASAIMO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
                      const Spacer(),
                      _StatusBadge(status: booking.status),
                    ]),
                    const SizedBox(height: 14),
                    Text(
                      booking.listingTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),

                // Tirets séparateurs (effet ticket)
                _DashedDivider(),

                // QR Code
                if (booking.qrToken != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(children: [
                      QrImageView(
                        data: booking.qrToken!,
                        version: QrVersions.auto,
                        size: 200,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Présentez ce code à l\'hôte',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ]),
                  ),

                _DashedDivider(),

                // Détails réservation
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Column(children: [
                    _DetailRow(label: 'N° Réservation', value: booking.id.substring(0, 10).toUpperCase()),
                    _DetailRow(label: 'Voyageur', value: booking.guestName),
                    _DetailRow(label: 'Arrivée', value: AppUtils.formatDate(booking.checkIn)),
                    _DetailRow(label: 'Départ', value: AppUtils.formatDate(booking.checkOut)),
                    _DetailRow(label: 'Durée', value: '${booking.nights} nuit${booking.nights > 1 ? 's' : ''}'),
                    _DetailRow(label: 'Voyageurs', value: '${booking.guests} personne${booking.guests > 1 ? 's' : ''}'),
                    _DetailRow(label: 'Paiement', value: booking.paymentMethod.toUpperCase().replaceAll('_', ' ')),
                  ]),
                ),

                _DashedDivider(),

                // Total
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
                    Text(
                      AppUtils.formatPrice(booking.total),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
                    ),
                  ]),
                ),

                // Pied de ticket
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Text(
                    'Merci de votre confiance · casaimo.app',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 28),
            if (booking.status == BookingStatus.checkedIn)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('Enregistrement confirmé par l\'hôte', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFF1B5E20), shape: BoxShape.circle)),
      Expanded(
        child: LayoutBuilder(builder: (ctx, constraints) {
          const dashW = 8.0;
          const gap = 5.0;
          final count = (constraints.maxWidth / (dashW + gap)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(count, (_) => Container(width: dashW, height: 1.5, color: Colors.grey.shade300)),
          );
        }),
      ),
      Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFF1B5E20), shape: BoxShape.circle)),
    ]);
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BookingStatus.confirmed  => Colors.white,
      BookingStatus.checkedIn  => Colors.lightBlueAccent,
      BookingStatus.completed  => Colors.white70,
      _                        => Colors.white70,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(status.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
