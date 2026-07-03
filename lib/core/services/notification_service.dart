import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

// Doit être top-level — s'exécute quand l'app est en arrière-plan/fermée
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {}

class NotificationService {
  NotificationService._();

  static final _fm = FirebaseMessaging.instance;
  static final _localNotifs = FlutterLocalNotificationsPlugin();
  static GoRouter? _router;

  static const _channelId   = 'casaimo_notifications';
  static const _channelName = 'CasaImo';

  // Appelé une seule fois dans main()
  static Future<void> init() async {
    // flutter_local_notifications et dart:io Platform.* ne sont pas supportés
    // sur le web — les notifications push web nécessitent une config à part
    // (VAPID key + service worker) et ne sont pas implémentées ici.
    if (kIsWeb) return;

    // 1. Demande de permission (iOS + Android 13+)
    final settings = await _fm.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 2. Init flutter_local_notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifs.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotifTap,
    );

    // 3. Créer le channel Android (obligatoire sur Android 8+)
    if (Platform.isAndroid) {
      await _localNotifs
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId, _channelName,
            importance: Importance.high,
            playSound: true,
          ));
    }

    // 4. Handler messages background/terminated
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // 5. iOS — afficher notifications en foreground
    await _fm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // 6. Messages reçus quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen(_showLocal);

    // 7. L'app est ouverte via un tap sur notification (background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _navigate(msg.data['route'] as String?);
    });

    // 8. L'app était fermée, ouverte via notification
    final initial = await _fm.getInitialMessage();
    if (initial != null) {
      _navigate(initial.data['route'] as String?);
    }
  }

  // Appelé depuis CasaImoApp.build() pour câbler la navigation
  static void setRouter(GoRouter router) => _router = router;

  // Affiche une notification locale quand l'app est au premier plan
  static Future<void> _showLocal(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await _localNotifs.show(
      n.hashCode,
      n.title ?? 'CasaImo',
      n.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['route'] as String?,
    );
  }

  // Tap sur la notification locale
  static void _onNotifTap(NotificationResponse response) {
    _navigate(response.payload);
  }

  static void _navigate(String? route) {
    if (route != null && route.isNotEmpty) {
      _router?.go(route);
    }
  }

  // Obtenir + sauvegarder le token FCM dans Firestore
  static Future<void> saveTokenForUser(String uid) async {
    try {
      final token = await _fm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': token});
      }
      // Refresh automatique du token
      _fm.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': newToken})
            .ignore();
      });
    } catch (_) {}
  }

  // Supprimer le token à la déconnexion
  static Future<void> clearTokenForUser(String uid) async {
    try {
      await _fm.deleteToken();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': FieldValue.delete()});
    } catch (_) {}
  }
}
