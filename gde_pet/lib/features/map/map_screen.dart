import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/pet_provider.dart';
import '../../models/pet_model.dart';
import '../home/pet_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static final LatLng _astanaCenter = LatLng(51.169392, 71.449074);

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    final petProvider = context.read<PetProvider>();
    // Загружаем все активные объявления
    await petProvider.loadPets();
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pets = petProvider.pets.where((pet) => 
        pet.isActive && 
        pet.latitude != null && 
        pet.longitude != null
    ).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.favorite_border,
            color: Colors.black,
            size: 28,
          ),
          onPressed: () {},
        ),
        title: const Text(
          'Карта',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _astanaCenter, 
          initialZoom: 12.0,
          onTap: (tapPosition, point) {
            // Можно добавить логику для добавления новых объявлений
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.zharkynismagulov.gde_pet', 
          ),
          MarkerLayer(
            markers: pets.map((pet) => _buildPetMarker(pet)).toList(),
          ),
        ],
      ),
    );
  }

  Marker _buildPetMarker(PetModel pet) {
    return Marker(
      point: LatLng(pet.latitude!, pet.longitude!),
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () => _openPetDetail(pet),
        child: Container(
          decoration: BoxDecoration(
            color: pet.status == PetStatus.lost 
                ? const Color(0xFFEE8A9A) 
                : const Color(0xFFD6C9FF),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            pet.type == PetType.dog 
                ? Icons.pets 
                : pet.type == PetType.cat 
                    ? Icons.pets 
                    : Icons.pets,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _openPetDetail(PetModel pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(pet: pet),
      ),
    );
  }
}
