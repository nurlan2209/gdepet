import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/profile_provider.dart';
import '../../models/pet_model.dart';
import 'location_picker_screen.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _petNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  PetType _selectedType = PetType.cat;
  PetStatus _selectedStatus = PetStatus.lost;
  LatLng? _selectedLocation;
  bool _useMapLocation = false;

  @override
  void dispose() {
    _petNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _images.addAll(pickedFiles);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выбора изображений: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _images.add(photo);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при съемке: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _pickLocationOnMap() async {
    final location = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: _selectedLocation,
        ),
      ),
    );

    if (location != null) {
      setState(() {
        _selectedLocation = location;
        _useMapLocation = true;
        _addressController.clear();
      });
    }
  }

  Future<void> _createPet() async {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы одну фотографию'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_useMapLocation && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Укажите место на карте или введите адрес'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final petProvider = context.read<PetProvider>();

    if (authProvider.user == null) return;

    final profile = profileProvider.profile;
    final ownerName = profile?.displayName ?? 
        authProvider.user?.displayName ?? 
        'Пользователь';

    final success = await petProvider.createPet(
      userId: authProvider.user!.uid,
      ownerName: ownerName,
      petName: _petNameController.text.trim(),
      description: _descriptionController.text.trim(),
      images: _images,
      type: _selectedType,
      status: _selectedStatus,
      latitude: _selectedLocation?.latitude,
      longitude: _selectedLocation?.longitude,
      address: _useMapLocation ? null : _addressController.text.trim(),
      contactPhone: _phoneController.text.trim().isNotEmpty 
          ? _phoneController.text.trim() 
          : profile?.phoneNumber,
      contactTelegram: _telegramController.text.trim().isNotEmpty
          ? _telegramController.text.trim()
          : profile?.telegramTag,
    );

    if (mounted) {
      if (success) {
        await petProvider.loadUserPets(authProvider.user!.uid);
        await petProvider.loadPets();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Объявление создано'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              petProvider.error ?? 'Ошибка создания объявления',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Создать объявление',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... (rest of the UI is the same)
              const Text(
                'Статус',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusChip(
                      label: 'Пропал',
                      status: PetStatus.lost,
                      isSelected: _selectedStatus == PetStatus.lost,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusChip(
                      label: 'Найден',
                      status: PetStatus.found,
                      isSelected: _selectedStatus == PetStatus.found,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Тип животного',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: PetType.values.map((type) {
                  return ChoiceChip(
                    label: Text(type.displayName),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedType = type;
                        });
                      }
                    },
                    selectedColor: const Color(0xFFEE8A9A),
                    labelStyle: TextStyle(
                      color: _selectedType == type ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              const Text(
                'Фотографии',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: _images.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Загрузите фотографии',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: _takePhoto,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Камера'),
                                ),
                                const SizedBox(width: 16),
                                TextButton.icon(
                                  onPressed: _pickImages,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Галерея'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        itemCount: _images.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _images.length) {
                            return _buildAddPhotoButton();
                          }
                          return _buildPhotoItem(index);
                        },
                      ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Кличка питомца',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _petNameController,
                decoration: const InputDecoration(hintText: 'Мурзик'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите кличку';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              const Text(
                'Особые приметы',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Коричневого цвета, белые пятна на лапках',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите описание';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              const Text(
                'Место',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickLocationOnMap,
                      icon: const Icon(Icons.map),
                      label: Text(
                        _selectedLocation == null
                            ? 'Выбрать на карте'
                            : 'Местоположение выбрано',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _useMapLocation
                            ? const Color(0xFFEE8A9A)
                            : Colors.black,
                        side: BorderSide(
                          color: _useMapLocation
                              ? const Color(0xFFEE8A9A)
                              : Colors.grey,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _useMapLocation = false;
                          _selectedLocation = null;
                        });
                      },
                      icon: const Icon(Icons.edit_location),
                      label: const Text('Ввести адрес'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: !_useMapLocation
                            ? const Color(0xFFEE8A9A)
                            : Colors.black,
                        side: BorderSide(
                          color: !_useMapLocation
                              ? const Color(0xFFEE8A9A)
                              : Colors.grey,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (!_useMapLocation) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'Астана, район Есиль',
                  ),
                ),
              ],

              if (_selectedLocation != null && _useMapLocation) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Выбранное местоположение:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Широта: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Долгота: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              const Text(
                'Контактная информация',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  hintText: 'Номер телефона (необязательно)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _telegramController,
                decoration: const InputDecoration(
                  hintText: 'Telegram (необязательно)',
                  prefixIcon: Icon(Icons.telegram),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: petProvider.isLoading ? null : _createPet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEE8A9A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: petProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Создать объявление',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required PetStatus status,
    required bool isSelected,
  }) {
    // ... same as before
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEE8A9A) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFFEE8A9A) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FutureBuilder<Uint8List>(
              future: _images[index].readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    width: 150,
                    height: 180,
                    fit: BoxFit.cover,
                  );
                }
                return const SizedBox(
                  width: 150,
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    // ... same as before
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate, size: 32),
          ),
          const Text('Добавить', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
