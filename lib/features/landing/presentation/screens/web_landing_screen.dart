import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../../shared/widgets/cards/search_listing_card.dart';

/// Page d'accueil marketing affichée uniquement sur le web (kIsWeb),
/// avant connexion — présente CasaImo comme un vrai site vitrine.
class WebLandingScreen extends ConsumerStatefulWidget {
  const WebLandingScreen({super.key});

  @override
  ConsumerState<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends ConsumerState<WebLandingScreen> {
  final _scrollCtrl = ScrollController();
  final _howKey = GlobalKey();
  final _listingsKey = GlobalKey();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToTop() {
    _scrollCtrl.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final listingsAsync = ref.watch(nearbyListingsProvider);
    final listings = listingsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _NavBar(
            onLogo: _scrollToTop,
            onHow: () => _scrollTo(_howKey),
            onListings: () => _scrollTo(_listingsKey),
            onLogin: () => context.go('/login'),
            onHost: () => context.go('/signup/host'),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              child: Column(
                children: [
                  _Hero(isDesktop: isDesktop, listings: listings),
                  _HowItWorks(key: _howKey),
                  _FeaturedListings(key: _listingsKey, listings: listings, isDesktop: isDesktop),
                  _CtaBanner(
                    onSearch: () => context.go('/login'),
                    onHost: () => context.go('/signup/host'),
                  ),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barre de navigation ───────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final VoidCallback onLogo;
  final VoidCallback onHow;
  final VoidCallback onListings;
  final VoidCallback onLogin;
  final VoidCallback onHost;

  const _NavBar({
    required this.onLogo,
    required this.onHow,
    required this.onListings,
    required this.onLogin,
    required this.onHost,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: onLogo,
          child: Row(children: [
            ClipOval(
              child: Image.asset('assets/images/logo1.png', width: 34, height: 34, fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.home_rounded, color: AppColors.primary)),
            ),
            const SizedBox(width: 8),
            const Text('CasaImo',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textPrimary)),
          ]),
        ),
        const SizedBox(width: 40),
        if (isDesktop) ...[
          _NavLink('Accueil', onLogo),
          _NavLink('Comment ça marche', onHow),
          _NavLink('Annonces', onListings),
        ],
        const Spacer(),
        TextButton(
          onPressed: onLogin,
          child: const Text('Connexion', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onHost,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          icon: const Icon(Icons.add_home_rounded, size: 18),
          label: Text(isDesktop ? 'Publier mon annonce' : 'Publier'),
        ),
      ]),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: TextButton(
      onPressed: onTap,
      child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
    ),
  );
}

// ── Hero ───────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final bool isDesktop;
  final List<ListingModel> listings;
  const _Hero({required this.isDesktop, required this.listings});

  @override
  Widget build(BuildContext context) {
    final heroImage = listings.isNotEmpty && listings.first.mediaUrls.isNotEmpty
        ? listings.first.mediaUrls.first
        : null;
    final avgRating = listings.isEmpty
        ? 0.0
        : listings.map((l) => l.avgRating).reduce((a, b) => a + b) / listings.length;

    final textCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Bénin · Logements meublés vérifiés',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const SizedBox(height: 20),
        Text(
          "L'art de séjourner,\noù que vous soyez.",
          style: TextStyle(
            fontSize: isDesktop ? 46 : 32,
            fontWeight: FontWeight.w900,
            height: 1.15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Studios, appartements et résidences meublées à Cotonou, Porto-Novo, '
          'Parakou, Abomey-Calavi, Ouidah et au-delà. Une expérience fluide, '
          'des hôtes vérifiés, des tarifs transparents.',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 28),
        Row(children: [
          FilledButton(
            onPressed: () => context.go('/login'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Trouver un logement', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => context.go('/signup/host'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: const BorderSide(color: AppColors.border),
            ),
            child: const Text('Devenir hôte', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
        ]),
        const SizedBox(height: 36),
        Row(children: [
          _StatItem(value: '${listings.length}+', label: 'biens actifs'),
          const SizedBox(width: 28),
          _StatItem(value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '—', label: 'note moyenne'),
          const SizedBox(width: 28),
          const _StatItem(value: '100%', label: 'contact direct hôte'),
        ]),
      ],
    );

    final imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: heroImage != null
            ? CachedNetworkImage(
                imageUrl: heroImage,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AppColors.surfaceVariant),
                errorWidget: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.home_rounded, size: 80, color: Colors.white70),
                ),
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.home_rounded, size: 80, color: Colors.white70),
              ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: isDesktop ? 64 : 32),
      child: isDesktop
          ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(flex: 5, child: textCol),
              const SizedBox(width: 48),
              Expanded(flex: 4, child: imageWidget),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              textCol,
              const SizedBox(height: 32),
              imageWidget,
            ]),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
  ]);
}

// ── Comment ça marche ─────────────────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({super.key});

  static const _steps = [
    (
      icon: Icons.search_rounded,
      color: AppColors.primary,
      title: 'Recherchez avec précision',
      text: 'Filtrez par ville, type de bien, prix et équipements. Trouvez le logement meublé idéal en quelques clics.',
    ),
    (
      icon: Icons.verified_user_rounded,
      color: Color(0xFF0288D1),
      title: 'Réservez en toute confiance',
      text: 'Consultez les photos réelles, les avis vérifiés et discutez directement avec l\'hôte avant de réserver.',
    ),
    (
      icon: Icons.qr_code_2_rounded,
      color: Color(0xFFF59E0B),
      title: 'Emménagez sereinement',
      text: 'Recevez votre ticket QR, présentez-le à l\'arrivée et profitez de votre séjour en toute sécurité.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Container(
      color: const Color(0xFFF8F9FA),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 56),
      child: Column(children: [
        const Text('Comment ça marche ?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        const SizedBox(height: 40),
        isDesktop
            ? Row(children: _steps.map((s) => Expanded(child: _StepCard(step: s))).toList())
            : Column(children: _steps.map((s) => _StepCard(step: s)).toList()),
      ]),
    );
  }
}

class _StepCard extends StatelessWidget {
  final ({IconData icon, Color color, String title, String text}) step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(10),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(color: step.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
        child: Icon(step.icon, color: step.color, size: 26),
      ),
      const SizedBox(height: 16),
      Text(step.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(step.text, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5)),
    ]),
  );
}

// ── Annonces mises en avant ───────────────────────────────────────────────────

class _FeaturedListings extends StatelessWidget {
  final List<ListingModel> listings;
  final bool isDesktop;
  const _FeaturedListings({super.key, required this.listings, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) return const SizedBox.shrink();
    final preview = listings.take(4).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 56),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Nos derniers logements',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('Découvrez un aperçu des biens disponibles sur CasaImo.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 28),
        if (isDesktop)
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: preview.map((l) => SizedBox(
              width: 300,
              child: SearchListingCard(
                listing: l,
                onTap: () => context.push('/listing/${l.id}'),
              ),
            )).toList(),
          )
        else
          Column(
            children: preview.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SearchListingCard(
                listing: l,
                onTap: () => context.push('/listing/${l.id}'),
              ),
            )).toList(),
          ),
      ]),
    );
  }
}

// ── Bannière CTA ───────────────────────────────────────────────────────────────

class _CtaBanner extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onHost;
  const _CtaBanner({required this.onSearch, required this.onHost});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(children: [
        const Text('Prêt à emménager ?',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 10),
        const Text(
          'Rejoignez les voyageurs et hôtes qui font confiance à CasaImo pour trouver leur logement meublé idéal.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 28),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
          FilledButton(
            onPressed: onSearch,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Je cherche un logement',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          OutlinedButton(
            onPressed: onHost,
            style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: const BorderSide(color: Colors.white54),
            ),
            child: const Text('Je suis propriétaire', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ]),
      ]),
    );
  }
}

// ── Pied de page ───────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  static const _cities = ['Cotonou', 'Porto-Novo', 'Parakou', 'Abomey-Calavi', 'Ouidah'];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final columns = [
      _FooterColumn(title: 'Explorer', items: _cities),
      const _FooterColumn(title: 'Ressources', items: ['Comment ça marche', 'FAQ', 'Contact']),
      const _FooterColumn(title: 'Hôtes', items: ['Publier une annonce', 'Se connecter']),
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFF0F1F13),
      padding: EdgeInsets.fromLTRB(isDesktop ? 64 : 20, 48, isDesktop ? 64 : 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        isDesktop
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Expanded(flex: 2, child: _FooterBrand()),
                ...columns.map((c) => Expanded(child: c)),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _FooterBrand(),
                const SizedBox(height: 28),
                ...columns,
              ]),
        const SizedBox(height: 32),
        const Divider(color: Colors.white12),
        const SizedBox(height: 16),
        const Text('© 2026 CasaImo — Tous droits réservés.',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      ClipOval(
        child: Image.asset('assets/images/logo1.png', width: 30, height: 30, fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(Icons.home_rounded, color: Colors.white, size: 20)),
      ),
      const SizedBox(width: 8),
      const Text('CasaImo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
    ]),
    const SizedBox(height: 12),
    const Text(
      'La plateforme de référence pour trouver un logement meublé de confiance au Bénin.',
      style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
    ),
  ]);
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;
  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      const SizedBox(height: 14),
      ...items.map((i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(i, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      )),
    ]),
  );
}
