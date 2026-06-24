import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/layout/call_options_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/message_model.dart';

final _messagesStreamProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, conversationId) {
  return FirebaseFirestore.instance
      .collection('messages')
      .doc(conversationId)
      .collection('msgs')
      .orderBy('sentAt')
      .snapshots()
      .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
});

final _conversationProvider =
    StreamProvider.family<ConversationModel?, String>((ref, id) {
  return FirebaseFirestore.instance
      .collection('messages')
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? ConversationModel.fromFirestore(doc) : null);
});

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() => _sending = true);
    _ctrl.clear();

    try {
      final msg = MessageModel(
        id: '',
        senderId: user.id,
        text: text,
        sentAt: DateTime.now(),
        isRead: false,
      );
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.conversationId)
          .collection('msgs')
          .add(msg.toFirestore());

      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.conversationId)
          .update({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount.${user.id}': 0,
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final asyncMessages =
        ref.watch(_messagesStreamProvider(widget.conversationId));
    final conv = ref.watch(_conversationProvider(widget.conversationId)).valueOrNull;

    // Resolve display name: stored hostName, then listingTitle, then fallback
    final otherName = conv?.hostName.isNotEmpty == true
        ? conv!.hostName
        : (conv?.listingTitle.isNotEmpty == true ? conv!.listingTitle : 'Propriétaire');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: conv?.hostAvatar.isNotEmpty == true
                ? NetworkImage(conv!.hostAvatar)
                : null,
            child: conv?.hostAvatar.isEmpty != false
                ? Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              otherName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Row(children: [
              Container(
                width: 7, height: 7,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const Text(
                'En ligne',
                style: TextStyle(fontSize: 11, color: AppColors.success),
              ),
            ]),
          ]),
        ]),
        actions: [
          IconButton(
            onPressed: () => showCallOptionsSheet(
              context,
              hostId: conv?.hostId ?? '',
              hostName: otherName,
              hostPhone: conv?.hostPhone ?? '',
              hostAvatar: conv?.hostAvatar ?? '',
            ),
            icon: const Icon(Icons.call_rounded),
            tooltip: 'Appeler',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: asyncMessages.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (messages) => messages.isEmpty
                ? const Center(
                    child: Text(
                      'Démarrez la conversation',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _Bubble(
                      message: messages[i],
                      isMe: messages[i].senderId == user?.id,
                    ),
                  ),
          ),
        ),
        _InputBar(
          controller: _ctrl,
          onSend: _send,
          sending: _sending,
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _Bubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            message.text,
            style: TextStyle(
              color: isMe
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppUtils.timeAgo(message.sentAt),
            style: TextStyle(
              fontSize: 10,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.textHint,
            ),
          ),
        ]),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;
  const _InputBar(
      {required this.controller, required this.onSend, required this.sending});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.attach_file_rounded,
              color: AppColors.textSecondary),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Écrire un message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: sending ? null : onSend,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: sending ? AppColors.textHint : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
