import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/layout/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class _NotifModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const _NotifModel({
    required this.id, required this.title, required this.body,
    required this.type, required this.isRead, required this.createdAt,
  });

  factory _NotifModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _NotifModel(
      id: doc.id,
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      type: d['type'] ?? 'info',
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

final _notifsProvider = StreamProvider<List<_NotifModel>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: user.id)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(_NotifModel.fromFirestore).toList());
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifs = ref.watch(_notifsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(ref),
            child: const Text('Tout lire'),
          ),
        ],
      ),
      body: asyncNotifs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (notifs) => notifs.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Aucune notification',
                subtitle: 'Vous serez notifié ici de toute activité sur votre compte.',
              )
            : ListView.separated(
                itemCount: notifs.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (_, i) => _NotifTile(
                  item: notifs[i],
                  onTap: () => _markRead(notifs[i].id),
                ),
              ),
      ),
    );
  }

  Future<void> _markRead(String notifId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  Future<void> _markAllRead(WidgetRef ref) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.id)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

class _NotifTile extends StatelessWidget {
  final _NotifModel item;
  final VoidCallback onTap;
  const _NotifTile({required this.item, required this.onTap});

  static IconData _icon(String type) => switch (type) {
    'booking' => Icons.check_circle_rounded,
    'payment' => Icons.payment_rounded,
    'review' => Icons.star_rounded,
    'message' => Icons.message_rounded,
    _ => Icons.notifications_rounded,
  };

  static Color _color(String type) => switch (type) {
    'booking' => AppColors.success,
    'payment' => AppColors.primary,
    'review' => AppColors.star,
    'message' => AppColors.info,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icon(item.type);
    final color = _color(item.type);
    return InkWell(
      onTap: onTap,
      child: Container(
        color: item.isRead ? null : AppColors.primaryContainer.withValues(alpha: 0.5),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Row(children: [
            Expanded(child: Text(item.title, style: Theme.of(context).textTheme.titleSmall)),
            if (!item.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          ]),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 2),
            Text(item.body, style: Theme.of(context).textTheme.bodySmall, maxLines: 2),
            const SizedBox(height: 4),
            Text(AppUtils.timeAgo(item.createdAt), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textHint)),
          ]),
        ),
      ),
    );
  }
}
