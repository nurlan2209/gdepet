import 'package:flutter/material.dart';
import 'package:gde_pet/features/home/pet_detail_screen.dart';
import 'package:gde_pet/features/notifications/notifications_screen.dart';
import 'package:provider/provider.dart'; // <--- ДОБАВЛЕНО
import '../../providers/pet_provider.dart'; // <--- ДОБАВЛЕНО
import '../../models/pet_model.dart'; // <--- ДОБАВЛЕНО
import '../../providers/auth_provider.dart'; // <--- ДОБАВЛЕНО
import '../../providers/profile_provider.dart';
import '../../providers/favorites_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Запускаем первоначальную загрузку данных
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final petProvider = context.read<PetProvider>();
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();
    
    // Загружаем объявления 'Пропал'
    await petProvider.loadPetsByStatus(PetStatus.lost);
    
    // Загружаем профиль пользователя, если он авторизован
    if (authProvider.user != null && profileProvider.profile == null) {
      await profileProvider.loadProfile(authProvider.user!.uid);
    }

    // Загружаем избранное, если пользователь авторизован
    if (authProvider.user != null) {
      await favoritesProvider.loadFavorites(authProvider.user!.uid);
    }
  }

  Future<void> _refreshData() async {
    final petProvider = context.read<PetProvider>();
    await petProvider.loadPetsByStatus(PetStatus.lost);
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    // Фильтруем данные по статусу для отображения в разных секциях
    final lostPets = petProvider.pets.where((p) => p.status == PetStatus.lost).toList();
    final foundPets = petProvider.pets.where((p) => p.status == PetStatus.found).toList();
    
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator( // <--- Обернули для обновления
          onRefresh: _refreshData,
          color: const Color(0xFFEE8A9A),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildAppBar(context),
              const SizedBox(height: 24),
              _buildSectionHeader('Пропали'),
              _buildHorizontalList(lostPets, PetStatus.lost),
              const SizedBox(height: 24),
              _buildSectionHeader('Найдены'),
              _buildHorizontalList(foundPets, PetStatus.found),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    
    // Используем данные из профиля, если они есть, иначе из AuthProvider
    final userName = profileProvider.profile?.displayName ?? 
        authProvider.userModel?.displayName ?? 
        'Пользователь';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          const CircleAvatar(radius: 24, backgroundColor: Colors.white),
          const SizedBox(width: 12),
          Text(
            'Привет, $userName',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none_outlined, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Обновлен для принятия списка PetModel
  Widget _buildHorizontalList(List<PetModel> pets, PetStatus status) {
    if (pets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Text(
          status == PetStatus.lost 
              ? 'Нет объявлений о пропавших питомцах.'
              : 'Нет объявлений о найденных питомцах.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pets.length,
        itemBuilder: (context, index) {
          final pet = pets[index];
          return PetCard(
            petModel: pet, // Передаем объект модели
            color: pet.status == PetStatus.lost 
                ? const Color(0xFFEE8A9A) 
                : const Color(0xFFD6C9FF),
            title: pet.petName,
            location: pet.address ?? 'На карте',
          );
        },
      ),
    );
  }
}

// PetCard обновлен для приема PetModel
class PetCard extends StatelessWidget {
  final PetModel petModel; // <--- НОВОЕ ПОЛЕ
  final Color color;
  final String title;
  final String location;

  const PetCard({
    super.key,
    required this.petModel, // <--- НОВОЕ ТРЕБОВАНИЕ
    required this.color,
    required this.title,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFav = favoritesProvider.isFavorite(petModel.id);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailScreen(pet: petModel), 
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded( // Добавлено Expanded для предотвращения переполнения
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (authProvider.user == null) return;
                    await favoritesProvider.toggleFavorite(authProvider.user!.uid, petModel.id);
                  },
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : Colors.black,
                  ),
                ),
              ],
            ),
            // TODO: Использовать Image.network(petModel.imageUrls.first)
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.black),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
