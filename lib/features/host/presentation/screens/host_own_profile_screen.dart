import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../listing/presentation/providers/listing_provider.dart';

class HostOwnProfileScreen extends ConsumerWidget {
  const HostOwnProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final listingsAsync = ref.watch(hostListingsStreamProvider(user.id));
    final listings = listingsAsync.valueOrNull ?? [];
    final avgRating = listings.isEmpty
        ? 0.0
        : listings.fold<double>(0, (s, l) => s + l.avgRating) / listings.length;
    final totalReviews = listings.fold<int>(0, (s, l) => s + l.reviewCount);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1565C0),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: user.avatarUrl.isNotEmpty
                                ? ClipOval(child: Image.network(user.avatarUrl, width: 68, height: 68, fit: BoxFit.cover))
                                : Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'H',
                                    style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Flexible(
                                child: Text(
                                  user.hasBusiness ? user.businessName : user.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user.isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, color: Colors.lightBlueAccent, size: 18),
                              ],
                            ]),
                            if (user.hasBusiness)
                              Text(user.name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            if (user.businessType.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(user.businessType, style: const TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                          ])),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Stats
                Row(children: [
                  _StatCard(value: '${listings.length}', label: 'Annonces', icon: Icons.home_work_rounded, color: const Color(0xFF1565C0)),
                  const SizedBox(width: 10),
                  _StatCard(
                    value: listings.isEmpty ? '-' : avgRating.toStringAsFixed(1),
                    label: 'Note moy.',
                    icon: Icons.star_rounded,
                    color: const Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 10),
                  _StatCard(value: '$totalReviews', label: 'Avis', icon: Icons.reviews_rounded, color: AppColors.primary),
                ]),
                const SizedBox(height: 20),

                // Verification status
                if (!user.isVerified)
                  _InfoBanner(
                    icon: Icons.shield_outlined,
                    title: 'Vérification en attente',
                    subtitle: 'Soumettez vos documents KYC pour obtenir le badge "Entreprise vérifiée".',
                    color: const Color(0xFFFF9800),
                    action: 'Vérifier mon compte',
                    onAction: () {},
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(children: [
                      Icon(Icons.verified_rounded, color: Color(0xFF1565C0), size: 20),
                      SizedBox(width: 10),
                      Text('Entreprise vérifiée', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
                    ]),
                  ),
                const SizedBox(height: 20),

                // Business info
                Text('Informations de l\'entreprise', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _InfoCard(children: [
                  _InfoRow(icon: Icons.business_rounded, label: 'Entreprise', value: user.hasBusiness ? user.businessName : 'Non renseigné'),
                  if (user.businessType.isNotEmpty)
                    _InfoRow(icon: Icons.category_rounded, label: 'Type', value: user.businessType),
                  if (user.businessAddress.isNotEmpty)
                    _InfoRow(icon: Icons.location_on_rounded, label: 'Adresse', value: user.businessAddress),
                  _InfoRow(icon: Icons.phone_rounded, label: 'Téléphone', value: user.phone.isNotEmpty ? user.phone : 'Non renseigné'),
                  _InfoRow(icon: Icons.email_rounded, label: 'Email', value: user.email),
                ]),

                if (user.businessDescription.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(user.businessDescription, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () => _editProfile(context, ref, user),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier le profil'),
                ),
                const SizedBox(height: 24),

                // Actions
                Text('Gestion', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.add_home_rounded,
                  label: 'Publier une nouvelle annonce',
                  color: AppColors.primary,
                  onTap: () => context.go('/host/listing/create'),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.home_work_rounded,
                  label: 'Mes annonces (${listings.length})',
                  color: const Color(0xFF1565C0),
                  onTap: () => context.go('/host/listings'),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.book_online_rounded,
                  label: 'Réservations',
                  color: const Color(0xFF9C27B0),
                  onTap: () => context.go('/host/bookings'),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Messages',
                  color: const Color(0xFF2196F3),
                  onTap: () => context.go('/host/messages'),
                ),
                const SizedBox(height: 24),

                // Sign out
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text('Se déconnecter', style: TextStyle(color: AppColors.error)),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref, dynamic user) async {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final bizCtrl = TextEditingController(text: user.businessName);
    final descCtrl = TextEditingController(text: user.businessDescription);

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom complet')),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone')),
            const SizedBox(height: 12),
            TextField(controller: bizCtrl, decoration: const InputDecoration(labelText: 'Nom entreprise')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enregistrer')),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;
    await FirebaseFirestore.instance.collection('users').doc(user.id).update({
      'name': nameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'businessName': bizCtrl.text.trim(),
      'businessDescription': descCtrl.text.trim(),
    });
    await ref.read(authProvider.notifier).refreshUser();
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, action;
  final Color color;
  final VoidCallback onAction;
  const _InfoBanner({required this.icon, required this.title, required this.subtitle, required this.action, required this.color, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onAction,
            child: Text(action, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13, decoration: TextDecoration.underline)),
          ),
        ])),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ]),
      ),
    );
  }
}
