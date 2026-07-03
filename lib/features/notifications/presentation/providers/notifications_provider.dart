import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/notification_model.dart';

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: user.id)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(NotificationModel.fromFirestore).toList());
});

final unreadNotifCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).valueOrNull
      ?.where((n) => !n.isRead)
      .length ?? 0;
});
