import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      icon: Icons.search_rounded,
      color: Color(0xFF4CAF50),
      title: 'Trouvez votre logement idéal',
      subtitle: 'Parcourez des milliers d\'annonces de villas, appartements, maisons et hôtels partout en Afrique.',
    ),
    _OnboardPage(
      icon: Icons.calendar_today_rounded,
      color: Color(0xFF2196F3),
      title: 'Réservez en quelques secondes',
      subtitle: 'Disponibilité en temps réel, réservation instantanée et paiement sécurisé Mobile Money ou carte.',
    ),
    _OnboardPage(
      icon: Icons.verified_rounded,
      color: Color(0xFF9C27B0),
      title: 'Logements vérifiés & sécurisés',
      subtitle: 'Tous nos propriétaires sont vérifiés. Profitez d\'avis authentiques et d\'une assistance 24h/24.',
    ),
  ];

  Future<void> _markSeenAndGo(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) context.go(route);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => _markSeenAndGo('/role-select'),
                child: const Text('Passer'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _ctrl,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.border,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (_page < _pages.length - 1) {
                        _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else {
                        _markSeenAndGo('/role-select');
                      }
                    },
                    child: Text(_page < _pages.length - 1 ? 'Suivant' : 'Créer un compte'),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Déjà un compte ?', style: Theme.of(context).textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => _markSeenAndGo('/login'),
                      child: const Text('Se connecter'),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _OnboardPage({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 48),
          Text(title, style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
