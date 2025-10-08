import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:gde_pet/features/messenger/chat_detail_screen.dart';
import 'package:gde_pet/services/chat_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/pet_model.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/pet_provider.dart';

class PetDetailScreen extends StatefulWidget {
  final PetModel pet;
  
  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {

  void _sharePet() {
    final pet = widget.pet;
    final text = 'Помогите найти! Пропал(а) ${pet.type.displayName.toLowerCase()} '
                 'по кличке "${pet.petName}".\n\n'
                 'Приметы: ${pet.description}\n\n'
                 'Смотрите подробности в приложении GdePet!';
    Share.share(text);
  }

  Future<void> _handleSeenSighting() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Для этого действия нужно войти в аккаунт')),
      );
      return;
    }

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Включите геолокацию')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет доступа к геолокации')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет доступа к геолокации')));
      return;
    } 

    try {
      final position = await Geolocator.getCurrentPosition();
      final petProvider = context.read<PetProvider>();
      final success = await petProvider.addSighting(
        petId: widget.pet.id,
        latitude: position.latitude,
        longitude: position.longitude,
        userId: authProvider.user!.uid,
      );
      if (mounted && success) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ваша отметка отправлена хозяину! Спасибо!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(petProvider.error ?? 'Не удалось добавить отметку'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка получения локации: $e')));
    }
  }

  Future<void> _callForHelp() async {
    final pet = widget.pet;
    const String phone = '+77771959900';
    final String lastLocation = pet.address ?? (pet.latitude != null ? 'https://maps.google.com/?q=${pet.latitude},${pet.longitude}' : 'Не указано');
    
    final message = 'Требуется помощь. Пропало животное: ${pet.petName}.\n'
                    'Приметы: ${pet.description}.\n'
                    'Последнее известное местоположение: $lastLocation';

    final whatsappUrl = Uri.parse("whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}");
    
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось открыть WhatsApp')),
          );
        }
      }
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
    }
  }

  Future<void> _openChat() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Для этого действия нужно войти в аккаунт')),
      );
      return;
    }
    
    final currentUserId = authProvider.user!.uid;
    final receiverId = widget.pet.userId;

    if (currentUserId == receiverId) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы не можете написать самому себе')),
      );
      return;
    }

    final chatService = ChatService();
    final chatId = await chatService.createOrGetChat(currentUserId, receiverId);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chatId,
            receiverId: receiverId,
            receiverName: widget.pet.ownerName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFav = authProvider.user != null && favoritesProvider.isFavorite(widget.pet.id);
    final statusColor = widget.pet.status == PetStatus.lost 
        ? const Color(0xFFEE8A9A) 
        : const Color(0xFFD6C9FF);
    
    return Scaffold(
      body: Stack(
        children: [
          // Pet Image
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            width: double.infinity,
            child: widget.pet.imageUrls.isNotEmpty
                ? Image.network(
                    widget.pet.imageUrls.first,
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
          
          // Back Button
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
          
          // Status
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
                widget.pet.status.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          // Info Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              width: double.infinity,
              decoration: const BoxDecoration(
                 color: Color(0xFFF9E1E1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Expanded(
                           child: Text(
                            widget.pet.petName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                                                   ),
                         ),
                        IconButton(
                          onPressed: () async {
                            if (authProvider.user == null) return;
                            await favoritesProvider.toggleFavorite(authProvider.user!.uid, widget.pet.id);
                          },
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.redAccent : Colors.black,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.pet.type.displayName} • ${widget.pet.ownerName}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          widget.pet.description,
                          style: const TextStyle(
                            fontSize: 16, 
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.pet.status == PetStatus.lost) ...[
           SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.visibility, color: Colors.white),
              onPressed: _handleSeenSighting,
              label: const Text('Видели? Жмите!', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _openChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEE8A9A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Написать хозяину', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  onPressed: _sharePet,
                  label: const Text('Поделиться'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
             Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.support_agent),
                  onPressed: _callForHelp,
                  label: const Text('Помощь'),
                   style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
