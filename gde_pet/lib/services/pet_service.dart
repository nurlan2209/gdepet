import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import '../models/pet_model.dart';
import '../models/user_model.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Future<String> createPet(PetModel pet) async {
    try {
      final docRef = await _firestore.collection('pets').add(pet.toJson());
      return docRef.id;
    } catch (e) {
      print('PetService (createPet) error: $e');
      throw 'Ошибка создания объявления: $e';
    }
  }

  // Загрузить фотографии питомца
  Future<List<String>> uploadPetPhotos(String petId, List<File> images) async {
    try {
      List<String> urls = [];
      
      for (int i = 0; i < images.length; i++) {
        // Убедимся, что файл существует
        if (!await images[i].exists()) {
          continue; 
        }
        
        final ref = _storage.ref().child('pets/$petId/photo_$i.jpg');
        // Используем PutFile, чтобы избежать ошибок с передачей
        final uploadTask = await ref.putFile(images[i]); 
        final url = await uploadTask.ref.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      print('PetService (uploadPetPhotos) error: $e');
      throw 'Ошибка загрузки фотографий: $e';
    }
  }


  Future<void> updatePetField(String id, Map<String, dynamic> fields) async {
  try {
    print('PetService: Updating pet fields for ID: $id');
    print('Fields: $fields');
    await _firestore.collection('pets').doc(id).update(fields);
    print('PetService: Pet fields updated successfully');
  } catch (e) {
    print('PetService (updatePetField) error: $e');
    throw 'Ошибка обновления объявления: $e';
  }
}

// Удалить объявление
Future<void> deletePet(String id) async {
  try {
    print('PetService: Deleting pet with ID: $id');
    
    // Сначала получаем объявление чтобы удалить фотографии
    final pet = await getPetById(id);
    
    if (pet != null && pet.imageUrls.isNotEmpty) {
      // Удаляем все фотографии из Storage
      for (String imageUrl in pet.imageUrls) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
          print('PetService: Deleted image: $imageUrl');
        } catch (e) {
          print('PetService: Failed to delete image $imageUrl: $e');
          // Продолжаем даже если не удалось удалить фото
        }
      }
    }
    
    // Удаляем документ из Firestore
    await _firestore.collection('pets').doc(id).delete();
    print('PetService: Pet deleted successfully');
  } catch (e) {
    print('PetService (deletePet) error: $e');
    throw 'Ошибка удаления объявления: $e';
  }
}

  // Получить все активные объявления
  Future<List<PetModel>> getAllActivePets() async {
    try {
      final snapshot = await _firestore
          .collection('pets')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PetModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('PetService (getAllActivePets) error: $e');
      throw 'Ошибка загрузки объявлений: $e';
    }
  }

  // Получить объявления по статусу
  Future<List<PetModel>> getPetsByStatus(PetStatus status) async {
    try {
      final statusString = status.toString().split('.').last;
      
      final snapshot = await _firestore
          .collection('pets')
          .where('status', isEqualTo: statusString)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PetModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('PetService (getPetsByStatus) error: $e');
      throw 'Ошибка загрузки объявлений: $e';
    }
  }

  // Получить объявления пользователя
  Future<List<PetModel>> getUserPets(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('pets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PetModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('PetService (getUserPets) error: $e');
      throw 'Ошибка загрузки объявлений пользователя: $e';
    }
  }

  // Получить объявление по ID
  Future<PetModel?> getPetById(String id) async {
    try {
      final doc = await _firestore.collection('pets').doc(id).get();
      
      // Явно проверяем существование и возвращаем null, если нет.
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      
      // Если существует, возвращаем модель
      return PetModel.fromJson({...doc.data()!, 'id': doc.id});
      
    } catch (e) {
      print('PetService (getPetById) error: $e');
      throw 'Ошибка загрузки объявления: $e';
    }
  }

  // Обновить объявление
  Future<void> updatePet(String id, PetModel pet) async {
    try {
      await _firestore.collection('pets').doc(id).update(pet.toJson());
    } catch (e) {
      print('PetService (updatePet) error: $e');
      throw 'Ошибка обновления объявления: $e';
    }
  }

  // Деактивировать объявление
  Future<void> deactivatePet(String id) async {
    try {
      await _firestore.collection('pets').doc(id).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('PetService (deactivatePet) error: $e');
      throw 'Ошибка деактивации объявления: $e';
    }
  }

  // Поиск объявлений рядом с координатами (используя GeoHash)
  Future<List<PetModel>> searchNearbyPets({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final center = GeoFirePoint(GeoPoint(latitude, longitude));
      final collectionRef = _firestore.collection('pets');
      
      final geoQuery = GeoCollectionReference(collectionRef)
          .subscribeWithin(
            center: center,
            radiusInKm: radiusKm,
            field: 'geohash',
            geopointFrom: (data) {
              final lat = data['latitude'] as double?;
              final lon = data['longitude'] as double?;
              
              if (lat != null && lon != null) {
                return GeoPoint(lat, lon);
              }
              // CRITICAL FIX: Если компилятор строго требует GeoPoint (не GeoPoint?), 
              // мы не можем вернуть null. Генерируем исключение, чтобы удовлетворить 
              // требование non-nullable возврата.
              throw Exception('Invalid GeoPoint data in document. Document will be skipped.');
            },
            strictMode: true,
          );
      
      final querySnapshot = await geoQuery.first;
      
      final pets = querySnapshot
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data?['isActive'] == true;
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return PetModel.fromJson({...data, 'id': doc.id});
          })
          .toList();
      
      return pets;
    } catch (e) {
      print('PetService (searchNearbyPets) error: $e');
      throw 'Ошибка поиска объявлений: $e';
    }
  }

  // Альтернативный метод для синхронного поиска
  Stream<List<PetModel>> streamNearbyPets({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) {
    try {
      final center = GeoFirePoint(GeoPoint(latitude, longitude));
      final collectionRef = _firestore.collection('pets');
      
      return GeoCollectionReference(collectionRef)
          .subscribeWithin(
            center: center,
            radiusInKm: radiusKm,
            field: 'geohash',
            geopointFrom: (data) {
              final lat = data['latitude'] as double?;
              final lon = data['longitude'] as double?;
              
              if (lat != null && lon != null) {
                return GeoPoint(lat, lon);
              }
              // CRITICAL FIX: Если компилятор строго требует GeoPoint (не GeoPoint?), 
              // мы не можем вернуть null. Генерируем исключение, чтобы удовлетворить 
              // требование non-nullable возврата.
              throw Exception('Invalid GeoPoint data in document. Document will be skipped.');
            },
            strictMode: true,
          )
          .map((querySnapshot) {
            return querySnapshot
                .where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  return data?['isActive'] == true;
                })
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return PetModel.fromJson({...data, 'id': doc.id});
                })
                .toList();
          });
    } catch (e) {
      print('PetService (streamNearbyPets) error: $e');
      // В стриме лучше не пробрасывать throw, а возвращать пустой стрим или onError
      rethrow; 
    }
  }
}
