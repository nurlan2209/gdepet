import 'package:flutter/material.dart';
import 'dart:async';
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
        const SnackBar(
          content: Text('Для этого действия нужно войти в аккаунт'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('👀 Видели питомца?'),
        content: const Text(
          'Эта функция поможет владельцу найти питомца!\n\n'
          'Ваше текущее местоположение будет отправлено владельцу как место, '
          'где питомца видели в последний раз.\n\n'
          'Нужно разрешить доступ к геолокации.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Определение местоположения...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Включите геолокацию в настройках устройства'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Настройки',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Доступ к геолокации запрещен'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Нет доступа к геолокации'),
              content: const Text(
                'Доступ к геолокации запрещен навсегда.\n\n'
                'Пожалуйста, разрешите доступ в настройках приложения.',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEE8A9A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Настройки'),
                ),
              ],
            ),
          );
        }
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Превышено время ожидания');
          },
        );
        
        print('Got position: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('Error getting position: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось определить местоположение. Попробуйте еще раз'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final petProvider = context.read<PetProvider>();
      bool success = false;
      
      try {
        success = await petProvider.addSighting(
          petId: widget.pet.id,
          latitude: position.latitude,
          longitude: position.longitude,
          userId: authProvider.user!.uid,
        );
        
        print('Sighting added: $success');
      } catch (e) {
        print('Error adding sighting: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка отправки: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Спасибо! Ваша отметка отправлена владельцу',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                petProvider.error ?? 'Не удалось добавить отметку',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Unexpected error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _callForHelp() async {
    final pet = widget.pet;
    const String phone = '77771959900';
    
    String locationInfo;
    if (pet.address != null && pet.address!.isNotEmpty) {
      locationInfo = pet.address!;
    } else if (pet.latitude != null && pet.longitude != null) {
      locationInfo = 'Координаты: ${pet.latitude}, ${pet.longitude}\n'
                     'Карта: https://maps.google.com/?q=${pet.latitude},${pet.longitude}';
    } else {
      locationInfo = 'Местоположение не указано';
    }
    
    final message = '🆘 Требуется помощь!\n\n'
                    '🐾 Животное: ${pet.petName}\n'
                    '📋 Тип: ${pet.type.displayName}\n'
                    '📝 Приметы: ${pet.description}\n\n'
                    '📍 Местоположение:\n$locationInfo\n\n'
                    'Приложение: GdePet';

    final whatsappUrl = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}"
    );
    
    try {
      final canLaunch = await canLaunchUrl(whatsappUrl);
      
      if (canLaunch) {
        final launched = await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication,
        );
        
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось открыть WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('WhatsApp не найден'),
              content: const Text(
                'WhatsApp не установлен на вашем устройстве.\n\n'
                'Вы можете:\n'
                '• Установить WhatsApp из магазина приложений\n'
                '• Позвонить по номеру +7 777 195 99 00',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
                TextButton(
                  onPressed: () async {
                    final telUrl = Uri.parse('tel:+77771959900');
                    if (await canLaunchUrl(telUrl)) {
                      await launchUrl(telUrl);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Позвонить'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
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