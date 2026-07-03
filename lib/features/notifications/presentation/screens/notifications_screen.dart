import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/layout/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifs = ref.watch(notificationsProvider);

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
  final NotificationModel item;
  final VoidCallback onTap;
  const _NotifTile({required this.item, required this.onTap});

  static IconData _icon(NotificationType type) => switch (type) {
    NotificationType.newBooking ||
    NotificationType.bookingConfirmed ||
    NotificationType.bookingCheckedIn  => Icons.check_circle_rounded,
    NotificationType.bookingRejected   => Icons.cancel_rounded,
    NotificationType.payment           => Icons.payment_rounded,
    NotificationType.review            => Icons.star_rounded,
    NotificationType.message           => Icons.message_rounded,
    NotificationType.info              => Icons.notifications_rounded,
  };

  static Color _color(NotificationType type) => switch (type) {
    NotificationType.newBooking ||
    NotificationType.bookingConfirmed ||
    NotificationType.bookingCheckedIn  => AppColors.success,
    NotificationType.bookingRejected   => AppColors.error,
    NotificationType.payment           => AppColors.primary,
    NotificationType.review            => AppColors.star,
    NotificationType.message           => AppColors.info,
    NotificationType.info              => AppColors.textSecondary,
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
