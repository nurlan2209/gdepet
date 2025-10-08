import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/pet_model.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';

class PetDetailScreen extends StatelessWidget {
  final PetModel pet;
  
  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFav = authProvider.user != null && favoritesProvider.isFavorite(pet.id);
    final statusColor = pet.status == PetStatus.lost 
        ? const Color(0xFFEE8A9A) 
        : const Color(0xFFD6C9FF);
    
    return Scaffold(
      body: Stack(
        children: [
          // Изображение питомца
          Container(
            height: MediaQuery.of(context).size.height * 0.7,
            width: double.infinity,
            child: pet.imageUrls.isNotEmpty
                ? Image.network(
                    pet.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/pet_image_placeholder.png',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    'assets/images/pet_image_placeholder.png',
                    fit: BoxFit.cover,
                  ),
          ),
          
          // Кнопка назад
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          
          // Статус питомца
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pet.status.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          // Информационная панель
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.petName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${pet.type.displayName} • ${pet.ownerName}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        pet.description,
                        style: const TextStyle(
                          fontSize: 16, 
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (pet.address != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pet.address!,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (pet.contactPhone != null || pet.contactTelegram != null) ...[
                        Row(
                          children: [
                            if (pet.contactPhone != null) ...[
                              const Icon(Icons.phone, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                pet.contactPhone!,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (pet.contactTelegram != null) ...[
                              const Icon(Icons.telegram, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                pet.contactTelegram!,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Кнопки действий
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.4 - 30,
            right: 24,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'fav_btn',
                  onPressed: () async {
                    if (authProvider.user == null) return;
                    await favoritesProvider.toggleFavorite(authProvider.user!.uid, pet.id);
                  },
                  backgroundColor: Colors.white,
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'share_btn',
                  onPressed: () {
                    // TODO: Реализовать функционал поделиться
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.share, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
