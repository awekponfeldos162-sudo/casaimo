import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Profile header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: user?.avatarUrl.isNotEmpty == true ? NetworkImage(user!.avatarUrl) : null,
                child: user?.avatarUrl.isEmpty != false
                    ? Text(
                        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(user?.name ?? 'Utilisateur', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
              if (user?.isVerified == true) ...[
                const SizedBox(height: 8),
                const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Compte vérifié', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                ]),
              ],
            ]),
          ),

          // Stats row
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _StatCard(label: 'Réservations', value: '0', icon: Icons.calendar_today_rounded),
                const SizedBox(width: 10),
                _StatCard(label: 'Favoris', value: '${user.favoriteIds.length}', icon: Icons.favorite_rounded),
                const SizedBox(width: 10),
                _StatCard(label: 'Avis', value: '0', icon: Icons.star_rounded),
              ]),
            ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Menu items
          if (user != null) ...[
            _MenuItem(icon: Icons.person_outline_rounded, label: 'Informations personnelles', onTap: () {}),
            _MenuItem(icon: Icons.calendar_today_rounded, label: 'Mes réservations', onTap: () => context.push('/booking-history')),
            _MenuItem(icon: Icons.favorite_border_rounded, label: 'Mes favoris', onTap: () => context.go('/favorites')),
            _MenuItem(icon: Icons.credit_card_rounded, label: 'Moyens de paiement', onTap: () {}),
            if (user.isHost)
              _MenuItem(icon: Icons.home_work_rounded, label: 'Espace hôte', onTap: () => context.go('/host/dashboard'), isHighlighted: true),
          ],

          const Divider(height: 1),
          _LanguageTile(),
          _MenuItem(icon: Icons.help_outline_rounded, label: 'Aide & Support', onTap: () {}),
          _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Confidentialité', onTap: () {}),
          _MenuItem(icon: Icons.settings_outlined, label: 'Paramètres', onTap: () {}),

          if (user != null) ...[
            const Divider(height: 1),
            _MenuItem(
              icon: Icons.logout_rounded,
              label: 'Se déconnecter',
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
              isDestructive: true,
            ),
          ] else ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(onPressed: () => context.go('/login'), child: const Text('Se connecter')),
            ),
          ],
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isHighlighted;

  const _MenuItem({
    required this.icon, required this.label, required this.onTap,
    this.isDestructive = false, this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : isHighlighted ? AppColors.primary : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(fontSize: 15, color: color, fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
      onTap: onTap,
    );
  }
}

// ── Sélecteur de langue ────────────────────────────────────────────────────────
class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l = AppL10n.of(context);
    final langLabel = locale.languageCode == 'fr' ? '🇫🇷 ${l.languageFr}' : '🇬🇧 ${l.languageEn}';

    return ListTile(
      leading: const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
      title: Text(l.language, style: const TextStyle(fontSize: 15)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(langLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
      ]),
      onTap: () => _showLanguagePicker(context, ref, locale),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, Locale current) {
    final l = AppL10n.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle bar
          Center(child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          )),
          Text(l.language, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          _LangOption(
            flag: '🇫🇷',
            label: l.languageFr,
            sublabel: 'Français',
            selected: current.languageCode == 'fr',
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(const Locale('fr'));
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _LangOption(
            flag: '🇬🇧',
            label: l.languageEn,
            sublabel: 'English',
            selected: current.languageCode == 'en',
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(const Locale('en'));
              Navigator.pop(context);
            },
          ),
        ]),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flag, label, sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _LangOption({required this.flag, required this.label, required this.sublabel, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryContainer : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        Text(flag, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: selected ? AppColors.primary : Colors.black87)),
          Text(sublabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        if (selected)
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
      ]),
    ),
  );
}
