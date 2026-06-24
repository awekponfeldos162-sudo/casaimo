import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HostAppScaffold extends StatelessWidget {
  final Widget child;
  const HostAppScaffold({super.key, required this.child});

  static const _tabs = [
    '/host/dashboard',
    '/host/listings',
    '/host/bookings',
    '/host/messages',
    '/host/profile',
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded, label: 'Accueil', selected: idx == 0, onTap: () => context.go('/host/dashboard'), color: const Color(0xFF1565C0)),
                _NavItem(icon: Icons.home_work_outlined, selectedIcon: Icons.home_work_rounded, label: 'Annonces', selected: idx == 1, onTap: () => context.go('/host/listings'), color: const Color(0xFF1565C0)),
                _NavItem(icon: Icons.book_online_outlined, selectedIcon: Icons.book_online_rounded, label: 'Réservations', selected: idx == 2, onTap: () => context.go('/host/bookings'), color: const Color(0xFF1565C0)),
                _NavItem(icon: Icons.chat_bubble_outline_rounded, selectedIcon: Icons.chat_bubble_rounded, label: 'Messages', selected: idx == 3, onTap: () => context.go('/host/messages'), color: const Color(0xFF1565C0)),
                _NavItem(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profil', selected: idx == 4, onTap: () => context.go('/host/profile'), color: const Color(0xFF1565C0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _NavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = selected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: selected
            ? BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? (selectedIcon ?? icon) : icon, color: c, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: c, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
