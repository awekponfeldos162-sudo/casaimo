import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
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
  final _picker = ImagePicker();
  bool _sending = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (mounted) {
      ref.invalidate(_messagesStreamProvider(widget.conversationId));
      ref.invalidate(_conversationProvider(widget.conversationId));
      setState(() => _ready = true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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

      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1080,
    );
    if (picked == null || !mounted) return;

    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() => _sending = true);

    try {
      final file = File(picked.path);
      final ext = picked.path.split('.').last.toLowerCase();
      final storageRef = FirebaseStorage.instance.ref(
        'chats/${widget.conversationId}/${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/$ext'),
      );
      final url = await storageRef.getDownloadURL();

      final msg = MessageModel(
        id: '',
        senderId: user.id,
        text: '',
        imageUrl: url,
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
        'lastMessage': '📷 Photo',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount.${user.id}': 0,
      });

      _scrollToBottom();
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur upload: ${e.message ?? e.code}'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Envoyer une image',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _AttachOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Galerie',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndSendImage(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AttachOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Caméra',
                      color: const Color(0xFF0288D1),
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndSendImage(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final asyncMessages =
        ref.watch(_messagesStreamProvider(widget.conversationId));
    final conv =
        ref.watch(_conversationProvider(widget.conversationId)).valueOrNull;

    final otherName = conv?.hostName.isNotEmpty == true
        ? conv!.hostName
        : (conv?.listingTitle.isNotEmpty == true
            ? conv!.listingTitle
            : 'Propriétaire');

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
            Text(otherName,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Row(children: [
              Container(
                width: 7, height: 7,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                    color: AppColors.success, shape: BoxShape.circle),
              ),
              const Text('En ligne',
                  style: TextStyle(fontSize: 11, color: AppColors.success)),
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
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Expanded(
                child: asyncMessages.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur: $e')),
                  data: (messages) => messages.isEmpty
                      ? const Center(
                          child: Text(
                            'Démarrez la conversation',
                            style:
                                TextStyle(color: AppColors.textSecondary),
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
              // Indicateur d'upload
              if (_sending && _ctrl.text.isEmpty)
                LinearProgressIndicator(
                  backgroundColor: AppColors.primaryContainer,
                  color: AppColors.primary,
                  minHeight: 2,
                ),
              _InputBar(
                controller: _ctrl,
                onSend: _send,
                onAttach: _showAttachSheet,
                sending: _sending,
              ),
            ]),
    );
  }
}

// ── Bulle de message ──────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _Bubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final hasImage = message.imageUrl != null;
    final hasText = message.text.isNotEmpty;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: radius,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              if (hasImage)
                GestureDetector(
                  onTap: () => _openFullImage(context, message.imageUrl!),
                  child: CachedNetworkImage(
                    imageUrl: message.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      height: 200,
                      color: isMe
                          ? AppColors.primary.withValues(alpha: 0.7)
                          : AppColors.surfaceVariant,
                      child: const Center(
                        child: SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      height: 120,
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded,
                            size: 36, color: AppColors.textHint),
                      ),
                    ),
                  ),
                ),

              // Texte
              if (hasText)
                Padding(
                  padding: EdgeInsets.fromLTRB(14, hasImage ? 8 : 10, 14, 4),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ),

              // Heure
              Padding(
                padding: EdgeInsets.fromLTRB(
                    14, hasText ? 2 : (hasImage ? 6 : 4), 14, 8),
                child: Text(
                  AppUtils.timeAgo(message.sentAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: PhotoView(
            imageProvider: NetworkImage(url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.5,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (_, _) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Barre de saisie ───────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool sending;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
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
          onPressed: onAttach,
          icon: const Icon(Icons.add_photo_alternate_rounded,
              color: AppColors.primary),
          tooltip: 'Envoyer une image',
        ),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: null,
            textInputAction: TextInputAction.newline,
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
            width: 44, height: 44,
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
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

// ── Option d'attachement ──────────────────────────────────────────────────────

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }
}
