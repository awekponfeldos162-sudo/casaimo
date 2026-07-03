import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/conversation_repository.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepository();
});

final conversationsStreamProvider = StreamProvider<List<ConversationModel>>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(conversationRepositoryProvider).watchByUser(user.id);
});

final messagesStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, id) {
  return ref.watch(conversationRepositoryProvider).watchMessages(id);
});

final conversationByIdProvider = StreamProvider.family<ConversationModel?, String>((ref, id) {
  return ref.watch(conversationRepositoryProvider).watchById(id);
});

final unreadMessagesCountProvider = Provider<int>((ref) {
  final user = ref.watch(authProvider);
  if (user == null) return 0;
  final conversations = ref.watch(conversationsStreamProvider).valueOrNull ?? [];
  int total = 0;
  for (final conv in conversations) {
    total += conv.unreadCount[user.id] ?? 0;
  }
  return total;
});
