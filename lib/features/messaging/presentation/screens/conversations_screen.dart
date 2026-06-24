import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/layout/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/message_model.dart';

final conversationsStreamProvider = StreamProvider<List<ConversationModel>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('messages')
      .where('participants', arrayContains: user.id)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ConversationModel.fromFirestore).toList());
});

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final asyncConversations = ref.watch(conversationsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: user == null
          ? EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Connectez-vous',
              subtitle: 'Accédez à vos messages avec les hôtes.',
              actionLabel: 'Se connecter',
              onAction: () => context.go('/login'),
            )
          : asyncConversations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (conversations) => conversations.isEmpty
                  ? const EmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Aucun message',
                      subtitle: 'Vos échanges avec les propriétaires apparaîtront ici.',
                    )
                  : ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (_, i) => _ConversationTile(
                        conversation: conversations[i],
                        currentUserId: user.id,
                        onTap: () => context.push('/chat/${conversations[i].id}'),
                      ),
                    ),
            ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount[currentUserId] ?? 0;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryContainer,
        child: Text(conversation.listingTitle.isNotEmpty ? conversation.listingTitle[0] : '?',
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      title: Text(conversation.listingTitle, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(conversation.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(AppUtils.timeAgo(conversation.lastMessageAt), style: Theme.of(context).textTheme.labelSmall),
        if (unread > 0) ...[
          const SizedBox(height: 4),
          Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Center(child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          ),
        ],
      ]),
    );
  }
}
