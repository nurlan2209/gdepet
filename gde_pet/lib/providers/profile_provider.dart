import 'dart:io';
import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  
  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Загрузить профиль
  Future<void> loadProfile(String uid) async {
    try {
      _setLoading(true);
      _error = null;

      _profile = await _profileService.getProfile(uid);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Обновить профиль
  Future<bool> updateProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? telegramTag,
    String? bio,
    String? city,
  }) async {
    if (_profile == null) return false;

    try {
      _setLoading(true);
      _error = null;

      final updatedProfile = _profile!.copyWith(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        telegramTag: telegramTag,
        bio: bio,
        city: city,
        updatedAt: DateTime.now(),
      );

      await _profileService.updateProfile(updatedProfile);
      _profile = updatedProfile;

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Загрузить фото профиля
  Future<bool> uploadProfilePhoto(String uid, File imageFile) async {
    try {
      _setLoading(true);
      _error = null;

      final photoUrl = await _profileService.uploadProfilePhoto(uid, imageFile);

      if (_profile != null) {
        final updatedProfile = _profile!.copyWith(
          photoURL: photoUrl,
          updatedAt: DateTime.now(),
        );
        await _profileService.updateProfile(updatedProfile);
        _profile = updatedProfile;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Удалить фото профиля
  Future<bool> deleteProfilePhoto(String uid) async {
    try {
      _setLoading(true);
      _error = null;

      await _profileService.deleteProfilePhoto(uid);

      if (_profile != null) {
        final updatedProfile = _profile!.copyWith(
          photoURL: null,
          updatedAt: DateTime.now(),
        );
        await _profileService.updateProfile(updatedProfile);
        _profile = updatedProfile;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Подписаться на обновления профиля
  void subscribeToProfile(String uid) {
    _profileService.getProfileStream(uid).listen((profile) {
      if (profile != null) {
        _profile = profile;
        notifyListeners();
      }
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _profile = null;
    _error = null;
    notifyListeners();
  }
}