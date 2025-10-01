import 'package:flutter/material.dart';
import 'package:gde_pet/features/profile/analytics_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Мой профиль',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.black,
              size: 28,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const CircleAvatar(radius: 60, backgroundColor: Color(0xFFE8FF8E)),
            const SizedBox(height: 16),
            const Text(
              'Adina',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            _buildProfileMenuItem(text: 'Изменить профиль', onTap: () {}),
            _buildProfileMenuItem(
              text: 'Аналитика',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsScreen(),
                  ),
                );
              },
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Выйти',
                style: TextStyle(color: Color(0xFFEE8A9A), fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
