import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../models/chat_model.dart';
import 'chat_detail_screen.dart';

class MessengerScreen extends StatefulWidget {
  const MessengerScreen({super.key});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Мессенджер',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Войдите, чтобы просматривать чаты'))
          : StreamBuilder<QuerySnapshot>(
              stream: _chatService.getChats(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Выводим ошибку в терминал
                  debugPrint('Ошибка в FutureBuilder/StreamBuilder: ${snapshot.error}');
                  debugPrint('StackTrace: ${snapshot.stackTrace}');

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Ошибка: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFEE8A9A),
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'У вас пока нет чатов',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Напишите владельцу питомца,\nчтобы начать переписку',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    try {
                      final chat = ChatModel.fromDocument(snapshot.data!.docs[index]);
                      return ChatListItem(chat: chat);
                    } catch (e) {
                      // Если не удалось распарсить чат, пропускаем его
                      print('Ошибка загрузки чата: $e');
                      return const SizedBox.shrink();
                    }
                  },
                );
              },
            ),
    );
  }
}

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  const ChatListItem({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user!.uid;
    final otherUserId = chat.users.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    
    if (otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final otherUserName = chat.userNames[otherUserId] ?? 'Пользователь';
    final otherUserPhoto = chat.userPhotos[otherUserId];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatId: chat.id,
              receiverId: otherUserId,
              receiverName: otherUserName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE8FF8E),
              backgroundImage: otherUserPhoto != null && otherUserPhoto.isNotEmpty
                  ? NetworkImage(otherUserPhoto)
                  : null,
              child: otherUserPhoto == null || otherUserPhoto.isEmpty
                  ? Text(
                      otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'П',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage.isNotEmpty
                        ? chat.lastMessage
                        : 'Начните переписку',
                    style: TextStyle(
                      color: chat.lastMessage.isEmpty
                          ? Colors.grey.shade400
                          : Colors.grey,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}