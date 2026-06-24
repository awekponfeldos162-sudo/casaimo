import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String bookingId;
  const BookingConfirmationScreen({super.key, required this.bookingId});

  String get _shortId => bookingId.length > 10 ? bookingId.substring(0, 10).toUpperCase() : bookingId.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(children: [

        // ── Header succès ────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Column(children: [
                // Icône succès animée
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Paiement Complet !',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre réservation a été enregistrée avec succès.\nLe propriétaire vous contactera sous 24h.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ),
        ),

        // ── Corps ────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [

              // N° de réservation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
                ),
                child: Column(children: [
                  const Text('N° de réservation', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      _shortId,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text('Réservation confirmée', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ]),
              ),

              const SizedBox(height: 14),

              // Statuts
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(children: [
                  _StatusRow(
                    icon: Icons.check_circle_rounded,
                    label: 'Statut réservation',
                    value: 'Confirmée',
                    valueColor: AppColors.primary,
                  ),
                  const Divider(height: 20),
                  _StatusRow(
                    icon: Icons.hourglass_empty_rounded,
                    label: 'Statut paiement',
                    value: 'En attente',
                    valueColor: AppColors.warning,
                  ),
                  const Divider(height: 20),
                  _StatusRow(
                    icon: Icons.schedule_rounded,
                    label: 'Demande soumise le',
                    value: _today(),
                    valueColor: Colors.black87,
                  ),
                ]),
              ),

              const SizedBox(height: 14),

              // Info note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'Une confirmation vous sera envoyée par SMS. Le propriétaire dispose de 24h pour valider votre demande.',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, height: 1.5),
                  )),
                ]),
              ),

              const SizedBox(height: 28),

              // Boutons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                  label: const Text("Retour à l'accueil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/booking-history'),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Voir mes réservations', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  String _today() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}/${n.month.toString().padLeft(2, '0')}/${n.year}';
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color valueColor;
  const _StatusRow({required this.icon, required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: AppColors.textSecondary),
    const SizedBox(width: 10),
    Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
    Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: valueColor)),
  ]);
}
