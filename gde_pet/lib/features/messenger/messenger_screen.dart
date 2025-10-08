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
                  return const Center(child: Text('Произошла ошибка'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'У вас пока нет чатов',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: snapshot.data!.docs.map((doc) {
                    final chat = ChatModel.fromDocument(doc);
                    return ChatListItem(chat: chat);
                  }).toList(),
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
    final otherUserId = chat.users.firstWhere((id) => id != currentUserId);
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
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: otherUserPhoto != null ? NetworkImage(otherUserPhoto) : null,
              child: otherUserPhoto == null ? const Icon(Icons.person) : null,
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage,
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
