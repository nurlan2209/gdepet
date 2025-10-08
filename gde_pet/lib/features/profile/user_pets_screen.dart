import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../models/pet_model.dart';
import '../profile/pet_management_screen.dart';

class UserPetsScreen extends StatefulWidget {
  const UserPetsScreen({super.key});

  @override
  State<UserPetsScreen> createState() => _UserPetsScreenState();
}

class _UserPetsScreenState extends State<UserPetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserPets();
    });
  }

  Future<void> _loadUserPets() async {
    final authProvider = context.read<AuthProvider>();
    final petProvider = context.read<PetProvider>();
    if (authProvider.user != null) {
      await petProvider.loadUserPets(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pets = petProvider.userPets;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Мои объявления',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserPets,
        color: const Color(0xFFEE8A9A),
        child: petProvider.isLoading && pets.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFEE8A9A)),
              )
            : pets.isEmpty
                ? const Center(
                    child: Text(
                      'Вы еще не создали ни одного объявления.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: pets.length,
                    itemBuilder: (context, index) {
                      final pet = pets[index];
                      // Создаем свою карточку вместо использования PetCard
                      return _buildUserPetCard(pet);
                    },
                  ),
      ),
    );
  }

  Widget _buildUserPetCard(PetModel pet) {
    final authProvider = context.watch<AuthProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFav = favoritesProvider.isFavorite(pet.id);
    final color = pet.status == PetStatus.lost
        ? const Color(0xFFEE8A9A)
        : const Color(0xFFD6C9FF);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetManagementScreen(pet: pet),
          ),
        ).then((result) {
          if (result == true) {
            _loadUserPets(); // Обновляем список после изменений
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с иконкой избранного
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pet.petName,
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
                      pet.id,
                    );
                  },
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : Colors.black,
                  ),
                ),
              ],
            ),
            
            // Изображение питомца (если есть)
            if (pet.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    pet.imageUrls.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white.withOpacity(0.3),
                        child: const Icon(
                          Icons.pets,
                          size: 40,
                          color: Colors.black54,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.pets,
                    size: 40,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 8),
            
            // Местоположение
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.black),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    pet.address ?? 'На карте',
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Индикатор статуса (активно/неактивно)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pet.isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pet.isActive ? 'Активно' : 'Неактивно',
                    style: TextStyle(
                      fontSize: 10,
                      color: pet.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.settings,
                  size: 16,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}