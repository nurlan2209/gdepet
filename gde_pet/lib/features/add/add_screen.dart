import 'package:flutter/material.dart';
import 'add_pet_screen.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Перенаправляем сразу на экран создания объявления
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AddPetScreen()),
      );
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFEE8A9A),
        ),
      ),
    );
  }
}