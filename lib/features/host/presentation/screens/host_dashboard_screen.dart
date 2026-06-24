import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../listing/presentation/providers/listing_provider.dart';

final _hostBookingsCountProvider = StreamProvider.family<int, String>((ref, hostId) {
  return FirebaseFirestore.instance
      .collection('bookings')
      .where('hostId', isEqualTo: hostId)
      .snapshots()
      .map((s) => s.docs.length);
});

class HostDashboardScreen extends ConsumerWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final hostId = user?.id ?? '';

    final listingsAsync = ref.watch(hostListingsStreamProvider(hostId));
    final bookingsAsync = ref.watch(_hostBookingsCountProvider(hostId));

    final listingCount = listingsAsync.maybeWhen(data: (l) => l.length, orElse: () => 0);
    final bookingCount = bookingsAsync.maybeWhen(data: (c) => c, orElse: () => 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace hôte'),
        actions: [
          IconButton(onPressed: () => context.go('/notifications'), icon: const Icon(Icons.notifications_none_rounded)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bonjour, ${user?.name.split(' ').first ?? 'Hôte'} 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Gérez vos annonces et réservations', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 20),
              Row(children: [
                _KpiChip(label: 'Annonces', value: '$listingCount'),
                const SizedBox(width: 10),
                _KpiChip(label: 'Réservations', value: '$bookingCount'),
                const SizedBox(width: 10),
                _KpiChip(label: 'Note moy.', value: '-'),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          Text('Actions rapides', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _ActionCard(icon: Icons.add_home_rounded, label: 'Nouvelle annonce', color: AppColors.primary, onTap: () => context.go('/host/listing/create')),
              _ActionCard(icon: Icons.list_alt_rounded, label: 'Mes annonces', color: const Color(0xFF2196F3), onTap: () => context.go('/host/listings')),
              _ActionCard(icon: Icons.calendar_month_rounded, label: 'Calendrier', color: const Color(0xFF9C27B0), onTap: () => context.go('/host/calendar')),
              _ActionCard(icon: Icons.receipt_long_rounded, label: 'Réservations', color: const Color(0xFFFF9800), onTap: () => context.go('/host/bookings')),
            ],
          ),
          const SizedBox(height: 24),

          Text('Activité récente', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _EmptyActivity(),
        ]),
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label, value;
  const _KpiChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.titleSmall),
        ]),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Column(children: [
          Icon(Icons.inbox_rounded, size: 40, color: AppColors.textHint),
          SizedBox(height: 10),
          Text('Aucune activité récente', style: TextStyle(color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
