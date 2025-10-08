import 'package:flutter/material.dart';
import 'package:gde_pet/features/home/pet_detail_screen.dart';
import 'package:gde_pet/features/notifications/notifications_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/pet_provider.dart';
import '../../models/pet_model.dart';
import '../../providers/auth_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final petProvider = context.read<PetProvider>();
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();
    
    // Загружаем ВСЕ активные объявления
    await petProvider.loadPets();
    
    if (authProvider.user != null && profileProvider.profile == null) {
      await profileProvider.loadProfile(authProvider.user!.uid);
    }

    if (authProvider.user != null) {
      await favoritesProvider.loadFavorites(authProvider.user!.uid);
    }
  }

  Future<void> _refreshData() async {
    final petProvider = context.read<PetProvider>();
    await petProvider.loadPets();
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    
    // Фильтруем по статусу ПОСЛЕ загрузки всех питомцев
    final lostPets = petProvider.pets
        .where((p) => p.status == PetStatus.lost && p.isActive)
        .toList();
    final foundPets = petProvider.pets
        .where((p) => p.status == PetStatus.found && p.isActive)
        .toList();
    
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
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
            petModel: pet,
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

class PetCard extends StatelessWidget {
  final PetModel petModel;
  final Color color;
  final String title;
  final String location;

  const PetCard({
    super.key,
    required this.petModel,
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
                Expanded(
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
                    await favoritesProvider.toggleFavorite(
                      authProvider.user!.uid, 
                      petModel.id,
                    );
                  },
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : Colors.black,
                  ),
                ),
              ],
            ),
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