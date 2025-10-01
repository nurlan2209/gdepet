import 'package:flutter/material.dart';
import 'package:gde_pet/features/messenger/chat_detail_screen.dart'; // <-- ИСПРАВЛЕНО ЗДЕСЬ

class MessengerScreen extends StatelessWidget {
  const MessengerScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: 4,
        itemBuilder: (context, index) {
          return const ChatListItem();
        },
      ),
    );
  }
}

class ChatListItem extends StatelessWidget {
  const ChatListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatDetailScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFFEE8A9A),
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Привет, Адина! Напоминаю, что у вас осталась одна незаконченная курсовая работа!',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Text('2', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
