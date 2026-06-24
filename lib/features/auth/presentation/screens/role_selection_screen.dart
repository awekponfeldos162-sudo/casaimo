import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(children: [

          // ── Section supérieure verte ─────────────────────────────────────
          Container(
            height: size.height * 0.32,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: Stack(children: [
              Positioned(top: -30, right: -30, child: _DecorCircle(size: 160, opacity: 0.07)),
              Positioned(bottom: 30, left: -50, child: _DecorCircle(size: 180, opacity: 0.05)),
              SafeArea(
                bottom: false,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/images/logo1.png', fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(Icons.home_rounded, size: 40, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Créez votre compte',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Choisissez votre profil pour continuer',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ]),
              ),
            ]),
          ),

          // ── Section choix de rôle ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(children: [

              _RoleCard(
                icon: Icons.person_search_rounded,
                title: 'Je suis Client',
                subtitle: 'Je cherche un logement, un appartement ou un hôtel.',
                features: const [
                  'Parcourir toutes les offres',
                  'Réserver en quelques clics',
                  'Payer par Mobile Money ou carte',
                  'Gérer mes réservations',
                ],
                color: AppColors.primary,
                gradient: const [Color(0xFF2E7D32), Color(0xFF43A047)],
                onTap: () => context.push('/signup/client'),
              ),

              const SizedBox(height: 14),

              _RoleCard(
                icon: Icons.apartment_rounded,
                title: 'Je suis Propriétaire',
                subtitle: 'Je propose un logement, une villa ou un hôtel.',
                features: const [
                  'Publier mes annonces avec photos & vidéo',
                  'Gérer mes réservations',
                  'Suivre mes revenus',
                  'Espace propriétaire dédié',
                ],
                color: AppColors.primaryDark,
                gradient: const [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                onTap: () => context.push('/signup/host'),
              ),

              const SizedBox(height: 24),

              // Déjà un compte
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Déjà un compte ?',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                TextButton(
                  onPressed: () => context.go('/login'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ]),

              const SizedBox(height: 20),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size, opacity;
  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: opacity), width: 1.5),
    ),
  );
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final List<String> features;
  final Color color;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // En-tête avec gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
              ),
            ]),
          ),

          // Features
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(children: [
                Icon(Icons.check_circle_rounded, color: color, size: 15),
                const SizedBox(width: 8),
                Flexible(child: Text(f, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              ]),
            )).toList()),
          ),
        ]),
      ),
    );
  }
}
