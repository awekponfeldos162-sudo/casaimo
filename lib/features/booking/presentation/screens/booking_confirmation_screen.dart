import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../data/models/booking_model.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String bookingId;
  const BookingConfirmationScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Réservation introuvable')),
          );
        }

        final booking = BookingModel.fromFirestore(snap.data!);
        return _ConfirmationBody(booking: booking);
      },
    );
  }
}

class _ConfirmationBody extends StatelessWidget {
  final BookingModel booking;
  const _ConfirmationBody({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(children: [
        _Header(status: booking.status),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
            child: Column(children: [
              // N° réservation
              _BookingIdCard(bookingId: booking.id),
              const SizedBox(height: 14),

              // Statut dynamique
              _StatusCard(booking: booking),
              const SizedBox(height: 14),

              // QR code (uniquement si confirmé)
              if (booking.status == BookingStatus.confirmed && booking.qrToken != null) ...[
                _QrCard(booking: booking),
                const SizedBox(height: 14),
              ],

              // Info contextuelle
              _InfoBanner(status: booking.status, rejectionReason: booking.rejectionReason),
              const SizedBox(height: 28),

              // Boutons
              if (booking.status == BookingStatus.confirmed && booking.qrToken != null)
                _ActionButton(
                  label: 'Voir mon ticket complet',
                  icon: Icons.receipt_long_rounded,
                  onTap: () => context.push('/booking-ticket/${booking.id}'),
                ),
              if (booking.status == BookingStatus.completed) ...[
                const SizedBox(height: 10),
                _ActionButton(
                  label: 'Laisser un avis',
                  icon: Icons.star_rounded,
                  onTap: () => context.push('/write-review', extra: booking),
                ),
              ],
              const SizedBox(height: 10),
              _ActionButton(
                label: "Retour à l'accueil",
                icon: Icons.home_rounded,
                onTap: () => context.go('/home'),
                outlined: true,
              ),
              const SizedBox(height: 8),
              _ActionButton(
                label: 'Mes réservations',
                icon: Icons.list_alt_rounded,
                onTap: () => context.go('/booking-history'),
                outlined: true,
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Header vert dynamique ─────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final BookingStatus status;
  const _Header({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle, colors) = switch (status) {
      BookingStatus.pendingApproval => (
          Icons.hourglass_top_rounded,
          'En attente de validation',
          'Le propriétaire va examiner votre demande et vous répondre sous 24h.',
          [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
        ),
      BookingStatus.confirmed => (
          Icons.check_circle_rounded,
          'Réservation confirmée !',
          'Votre QR code est prêt. Présentez-le à votre arrivée.',
          [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
        ),
      BookingStatus.rejected => (
          Icons.cancel_rounded,
          'Réservation refusée',
          'Le propriétaire n\'a pas pu accepter votre demande.',
          [const Color(0xFFB71C1C), const Color(0xFFC62828)],
        ),
      BookingStatus.checkedIn => (
          Icons.login_rounded,
          'Bienvenue !',
          'Votre enregistrement a été validé avec succès.',
          [const Color(0xFF0D47A1), const Color(0xFF1565C0)],
        ),
      _ => (
          Icons.check_rounded,
          'Réservation',
          '',
          [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
        ),
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Column(children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
              ),
              child: Icon(icon, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
    );
  }
}

// ── N° de réservation ─────────────────────────────────────────────────────────

class _BookingIdCard extends StatelessWidget {
  final String bookingId;
  const _BookingIdCard({required this.bookingId});

  String get _short => bookingId.length > 10 ? bookingId.substring(0, 10).toUpperCase() : bookingId.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        const Text('N° de réservation', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          child: Text(_short, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 3)),
        ),
      ]),
    );
  }
}

// ── Carte statut ──────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final BookingModel booking;
  const _StatusCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (booking.status) {
      BookingStatus.pendingApproval => AppColors.warning,
      BookingStatus.confirmed       => AppColors.primary,
      BookingStatus.rejected        => AppColors.error,
      BookingStatus.checkedIn       => Colors.blue,
      BookingStatus.active          => Colors.blue,
      BookingStatus.completed       => AppColors.primary,
      BookingStatus.cancelled       => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        _Row(icon: Icons.flag_rounded, label: 'Statut', value: booking.status.label, valueColor: statusColor),
        if (booking.hostName.isNotEmpty) ...[
          const Divider(height: 20),
          _Row(icon: Icons.person_rounded, label: 'Propriétaire', value: booking.hostName),
        ],
        const Divider(height: 20),
        _Row(icon: Icons.calendar_today_rounded, label: 'Arrivée', value: AppUtils.formatDate(booking.checkIn)),
        const Divider(height: 20),
        _Row(icon: Icons.calendar_today_rounded, label: 'Départ', value: AppUtils.formatDate(booking.checkOut)),
        const Divider(height: 20),
        _Row(icon: Icons.nights_stay_rounded, label: 'Durée', value: '${booking.nights} nuit${booking.nights > 1 ? 's' : ''}'),
        const Divider(height: 20),
        _Row(icon: Icons.people_rounded, label: 'Voyageurs', value: '${booking.guests}'),
        const Divider(height: 20),
        _Row(icon: Icons.receipt_rounded, label: 'Total', value: AppUtils.formatPrice(booking.total), bold: true),
      ]),
    );
  }
}

// ── QR code card ──────────────────────────────────────────────────────────────

class _QrCard extends StatelessWidget {
  final BookingModel booking;
  const _QrCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.qr_code_2_rounded, size: 20, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Votre ticket d\'entrée', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: QrImageView(
            data: booking.qrToken!,
            version: QrVersions.auto,
            size: 200,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Présentez ce QR code à l\'hôte lors de votre arrivée',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

// ── Bannière info contextuelle ────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final BookingStatus status;
  final String? rejectionReason;
  const _InfoBanner({required this.status, this.rejectionReason});

  @override
  Widget build(BuildContext context) {
    final (icon, text, bg, border) = switch (status) {
      BookingStatus.pendingApproval => (
          Icons.info_outline_rounded,
          'Le propriétaire dispose de 24h pour valider votre demande. Vous recevrez une notification dès qu\'il répond.',
          AppColors.primaryContainer,
          AppColors.primary.withValues(alpha: 0.2),
        ),
      BookingStatus.confirmed => (
          Icons.verified_rounded,
          'Réservation validée. Présentez votre QR code à l\'accueil. L\'hôte le scannera pour confirmer votre enregistrement.',
          const Color(0xFFE8F5E9),
          AppColors.primary.withValues(alpha: 0.2),
        ),
      BookingStatus.rejected => (
          Icons.info_outline_rounded,
          rejectionReason != null && rejectionReason!.isNotEmpty
              ? 'Motif : $rejectionReason'
              : 'Le propriétaire n\'a pas pu accepter votre demande pour le moment.',
          const Color(0xFFFFEBEE),
          AppColors.error.withValues(alpha: 0.2),
        ),
      _ => (
          Icons.info_outline_rounded,
          '',
          AppColors.primaryContainer,
          AppColors.border,
        ),
    };

    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: status == BookingStatus.rejected ? AppColors.error : AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: status == BookingStatus.rejected ? AppColors.error : AppColors.primary, height: 1.5))),
      ]),
    );
  }
}

// ── Boutons ───────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;
  const _ActionButton({required this.label, required this.icon, required this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white, size: 20),
              label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
    );
  }
}

// ── Row helper ────────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  final bool bold;
  const _Row({required this.icon, required this.label, required this.value, this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: AppColors.textSecondary),
    const SizedBox(width: 10),
    Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
    Text(value, style: TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      fontSize: bold ? 15 : 13,
      color: valueColor ?? Colors.black87,
    )),
  ]);
}
