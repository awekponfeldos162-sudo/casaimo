import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/client_signup_screen.dart';
import '../../features/auth/presentation/screens/host_signup_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/search/presentation/screens/search_results_screen.dart';
import '../../features/listing/presentation/screens/listing_detail_screen.dart';
import '../../features/booking/presentation/screens/booking_screen.dart';
import '../../features/booking/presentation/screens/booking_confirmation_screen.dart';
import '../../features/booking/presentation/screens/booking_detail_screen.dart';
import '../../features/messaging/presentation/screens/call_screen.dart';
import '../../features/messaging/presentation/screens/conversations_screen.dart';
import '../../features/messaging/presentation/screens/chat_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/host/presentation/screens/host_own_profile_screen.dart';
import '../../features/host/presentation/screens/host_public_profile_screen.dart';
import '../../features/profile/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/booking_history_screen.dart';
import '../../features/host/presentation/screens/host_dashboard_screen.dart';
import '../../features/host/presentation/screens/host_listings_screen.dart';
import '../../features/host/presentation/screens/create_listing_screen.dart';
import '../../features/host/presentation/screens/host_calendar_screen.dart';
import '../../features/host/presentation/screens/host_bookings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../shared/widgets/layout/app_scaffold.dart';
import '../../shared/widgets/layout/host_app_scaffold.dart';

// Notifie GoRouter quand l'auth change sans recréer le router
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<dynamic>(authProvider, (prev, next) => notifyListeners());
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: notifier,

    // ── Redirect automatique selon le rôle ──────────────────────────
    redirect: (context, state) {
      final user = ref.read(authProvider);
      final path = state.uri.path;
      final isAuth = user != null;
      final isHost = user?.isHost ?? false;

      // Écrans publics — jamais redirigés
      final publicPaths = ['/splash', '/onboarding', '/login', '/signup',
        '/role-select', '/signup/client', '/signup/host', '/otp'];
      if (publicPaths.any((p) => path.startsWith(p))) return null;

      // Non connecté → login
      if (!isAuth) return '/login';

      // Client qui tente d'accéder à un écran host → home
      // /host-profile est accessible aux clients (profil public du propriétaire)
      if (!isHost && path.startsWith('/host') && !path.startsWith('/host-profile')) return '/home';

      // Host qui tente d'accéder à l'app client → host dashboard
      if (isHost && (path == '/home' || path == '/search' ||
          path == '/favorites')) {
        return '/host/dashboard';
      }

      return null;
    },

    routes: [
      // ── Auth ────────────────────────────────────────────────────────
      GoRoute(path: '/splash',      builder: (_, state) => const SplashScreen()),
      GoRoute(path: '/onboarding',  builder: (_, state) => const OnboardingScreen()),
      GoRoute(path: '/login',       builder: (_, state) => const LoginScreen()),
      GoRoute(path: '/signup',      builder: (_, state) => const RoleSelectionScreen()),
      GoRoute(path: '/role-select', builder: (_, state) => const RoleSelectionScreen()),
      GoRoute(path: '/signup/client', builder: (_, state) => const ClientSignupScreen()),
      GoRoute(path: '/signup/host',   builder: (_, state) => const HostSignupScreen()),
      GoRoute(path: '/otp', builder: (_, state) => OtpScreen(phone: state.extra as String? ?? '')),

      // ── App Client (shell avec bottom nav client) ───────────────────
      ShellRoute(
        builder: (ctx, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(path: '/home',      builder: (_, state) => const HomeScreen()),
          GoRoute(
            path: '/search',
            builder: (_, state) => const SearchScreen(),
            routes: [
              GoRoute(
                path: 'results',
                builder: (_, state) => SearchResultsScreen(
                  query: (state.extra as Map<String, dynamic>?)?['query'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(path: '/favorites', builder: (_, state) => const FavoritesScreen()),
          GoRoute(path: '/messages',  builder: (_, state) => const ConversationsScreen()),
          GoRoute(path: '/profile',   builder: (_, state) => const ProfileScreen()),
        ],
      ),

      // ── App Propriétaire (shell avec bottom nav host) ───────────────
      ShellRoute(
        builder: (ctx, state, child) => HostAppScaffold(child: child),
        routes: [
          GoRoute(path: '/host/dashboard', builder: (_, state) => const HostDashboardScreen()),
          GoRoute(path: '/host/listings',  builder: (_, state) => const HostListingsScreen()),
          GoRoute(path: '/host/bookings',  builder: (_, state) => const HostBookingsScreen()),
          GoRoute(path: '/host/calendar',  builder: (_, state) => const HostCalendarScreen()),
          GoRoute(path: '/host/messages',  builder: (_, state) => const ConversationsScreen()),
          GoRoute(path: '/host/profile',   builder: (_, state) => const HostOwnProfileScreen()),
        ],
      ),

      // ── Écrans plein écran (hors shell) ────────────────────────────
      GoRoute(
        path: '/listing/:id',
        builder: (_, state) => ListingDetailScreen(listingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking/:listingId',
        builder: (_, state) => BookingScreen(listingId: state.pathParameters['listingId']!),
      ),
      GoRoute(
        path: '/booking-confirmation/:bookingId',
        builder: (_, state) => BookingConfirmationScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (_, state) => ChatScreen(conversationId: state.pathParameters['conversationId']!),
      ),
      GoRoute(
        path: '/host/listing/create',
        builder: (_, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/host/listing/:id/edit',
        builder: (_, state) => CreateListingScreen(listingId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/host-profile/:hostId',
        builder: (_, state) => HostPublicProfileScreen(hostId: state.pathParameters['hostId']!),
      ),
      GoRoute(path: '/booking-history',  builder: (_, state) => const BookingHistoryScreen()),
      GoRoute(
        path: '/booking-detail/:bookingId',
        builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(path: '/notifications',    builder: (_, state) => const NotificationsScreen()),
      GoRoute(
        path: '/call',
        builder: (_, state) {
          final e = state.extra as Map<String, dynamic>? ?? {};
          return CallScreen(
            calleeId:     e['calleeId']     as String? ?? '',
            calleeName:   e['calleeName']   as String? ?? 'Utilisateur',
            calleeAvatar: e['calleeAvatar'] as String? ?? '',
          );
        },
      ),
    ],

    errorBuilder: (ctx, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page introuvable', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ctx.go('/home'),
              child: const Text("Retour à l'accueil"),
            ),
          ],
        ),
      ),
    ),
  );
});
