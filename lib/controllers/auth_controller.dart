// lib/controllers/auth_controller.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import '../services/cartesia_service.dart';

class AuthController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  final name = ''.obs;
  final dob = Rx<DateTime?>(null);
  final avatarPath = ''.obs;
  final voiceRecordingPath = ''.obs;
  final selectedAvatarIndex = Rxn<int>();

  // Voice cloning state
  final isCloned = false.obs;
  final clonedVoiceId = ''.obs;
  final clonedVoiceName = ''.obs;

  final isLoading = false.obs;
  final isAuthenticated = false.obs;
  final uid = ''.obs;

  static const String _uidKey = "app_user_uid";
  static const String _nameKey = "app_user_name";
  static const String _dobKey = "app_user_dob";
  static const String _avatarKey = "app_user_avatar";
  static const String _voiceKey = "app_user_voice";
  static const String _isClonedKey = "app_user_is_cloned";
  static const String _clonedVoiceIdKey = "app_user_cloned_voice_id";
  static const String _clonedVoiceNameKey = "app_user_cloned_voice_name";

  @override
  void onInit() {
    super.onInit();
    // checkAuthStatus();
  }

  /// Generate UID only once
  void _generateUID() {
    if (uid.value.isEmpty) {
      uid.value = const Uuid().v4();
      debugPrint('🆔 Generated UID: ${uid.value}');
    }
  }

  /// Check local UID → determine route
  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUID = prefs.getString(_uidKey);

    if (storedUID != null && storedUID.isNotEmpty) {
      // Load into reactive variables
      uid.value = storedUID;
      name.value = prefs.getString(_nameKey) ?? '';
      avatarPath.value = prefs.getString(_avatarKey) ?? '';
      voiceRecordingPath.value = prefs.getString(_voiceKey) ?? '';

      // Load voice cloning status
      isCloned.value = prefs.getBool(_isClonedKey) ?? false;
      clonedVoiceId.value = prefs.getString(_clonedVoiceIdKey) ?? '';
      clonedVoiceName.value = prefs.getString(_clonedVoiceNameKey) ?? '';

      final storedDOB = prefs.getString(_dobKey);
      if (storedDOB != null) {
        dob.value = DateTime.tryParse(storedDOB);
      }

      isAuthenticated.value = true;

      debugPrint("🔐 User found. Loaded locally + Auto-login");
      debugPrint(
        "🎤 Voice cloning status: ${isCloned.value ? 'Cloned' : 'Not cloned'}",
      );
      if (isCloned.value) {
        debugPrint("🎤 Cloned voice ID: ${clonedVoiceId.value}");
      }

      Future.delayed(Duration.zero, () {
        // Get.offAllNamed('/home');
      });
    } else {
      debugPrint("🚀 No UID found. Starting onboarding.");

      Future.delayed(Duration.zero, () {
        // Get.offAllNamed('/onboarding');
      });
    }
  }

  /// Clone user's voice using Cartesia API
  Future<bool> cloneUserVoice() async {
    if (voiceRecordingPath.value.isEmpty) {
      debugPrint('❌ No voice recording path available');
      return false;
    }

    if (isCloned.value) {
      debugPrint('✅ Voice already cloned');
      return true;
    }

    try {
      isLoading.value = true;

      debugPrint('🎙️ Starting voice cloning process...');
      debugPrint('📁 Voice recording path: ${voiceRecordingPath.value}');

      final result = await CartesiaService.cloneVoice(
        audioFilePath: voiceRecordingPath.value,
        voiceName: '${name.value}\'s Voice',
        description: 'Cloned voice for ${name.value}',
        language: 'en',
      );

      if (result != null && result['id'] != null) {
        // Save to reactive variables
        clonedVoiceId.value = result['id'];
        clonedVoiceName.value = result['name'] ?? '${name.value}\'s Voice';
        isCloned.value = true;

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isClonedKey, true);
        await prefs.setString(_clonedVoiceIdKey, clonedVoiceId.value);
        await prefs.setString(_clonedVoiceNameKey, clonedVoiceName.value);

        // Update Supabase
        await supabase
            .from('users')
            .update({
              'cloned_voice_id': clonedVoiceId.value,
              'cloned_voice_name': clonedVoiceName.value,
              'cloned_voice_created_at': result['created_at'],
            })
            .eq('uid', uid.value);

        debugPrint('✅ Voice cloned successfully!');
        debugPrint('🎤 Voice ID: ${clonedVoiceId.value}');
        debugPrint('🎤 Voice Name: ${clonedVoiceName.value}');
        return true;
      } else {
        debugPrint('❌ Voice cloning failed - no result returned');

        Get.snackbar(
          'Voice Cloning Failed',
          'Could not clone your voice. Please try again later.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        return false;
      }
    } catch (e, stack) {
      debugPrint('❌ Voice cloning error: $e');
      debugPrintStack(stackTrace: stack);

      Get.snackbar(
        'Error',
        'Failed to clone voice: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Save UID locally
  Future<void> _saveUID(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uidKey, userId);
    debugPrint('💾 Saved UID locally: $userId');
  }

  /// Read UID from local
  Future<void> logout() async {
    try {
      isLoading.value = true; // show loading UI

      // Artificial loading delay (looks smoother)
      await Future.delayed(const Duration(milliseconds: 1200));

      final prefs = await SharedPreferences.getInstance();

      // Remove all stored onboarding/profile data
      await prefs.clear();

      debugPrint("🚪 Logged out. Cleared local data.");

      // Reset reactive values
      uid.value = '';
      name.value = '';
      dob.value = null;
      avatarPath.value = '';
      voiceRecordingPath.value = '';
      selectedAvatarIndex.value = null;
      isAuthenticated.value = false;
      isCloned.value = false;
      clonedVoiceId.value = '';
      clonedVoiceName.value = '';

      // Navigate to onboarding
      Future.delayed(Duration.zero, () {
        Get.offAllNamed('/onboarding');
      });
    } catch (e) {
      debugPrint("❌ Logout error: $e");
      Get.snackbar(
        "Error",
        "Logout failed",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      // Add tiny delay so loading doesn't disappear instantly
      await Future.delayed(const Duration(milliseconds: 300));
      isLoading.value = false;
    }
  }

  /// Name validation
  bool validateName() {
    if (name.value.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your name',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    if (name.value.trim().length < 2) {
      Get.snackbar(
        'Error',
        'Name must be at least 2 characters',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  /// DOB validation
  bool validateDOB() {
    if (dob.value == null) {
      Get.snackbar(
        'Error',
        'Please select your date of birth',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    final age = DateTime.now().difference(dob.value!).inDays ~/ 365;
    if (age < 13) {
      Get.snackbar(
        'Error',
        'You must be at least 13 years old',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  /// Avatar validation
  bool validateAvatar() {
    if (selectedAvatarIndex.value == null || avatarPath.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select an avatar',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  /// Upload audio file
  Future<String?> uploadVoiceRecording(File audioFile) async {
    try {
      isLoading.value = true;

      final fileName =
          '${uid.value}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${uid.value}/$fileName';

      await supabase.storage
          .from(SupabaseConfig.voiceRecordingsBucket)
          .upload(
            filePath,
            audioFile,
            fileOptions: const FileOptions(
              contentType: 'audio/mp4',
              upsert: false,
            ),
          );

      final publicUrl = supabase.storage
          .from(SupabaseConfig.voiceRecordingsBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      Get.snackbar(
        'Upload Error',
        'Failed to upload voice recording',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Final onboarding + save UID locally
  Future<bool> completeOnboarding(String voiceRecordingUrl) async {
    try {
      isLoading.value = true;

      if (uid.value.isEmpty) _generateUID();

      final dobString = dob.value!.toIso8601String().split('T')[0];

      await supabase.from('users').insert({
        'uid': uid.value,
        'name': name.value.trim(),
        'dob': dob.value!.toIso8601String().split('T')[0],
        'avatar_path': avatarPath.value,
        'voice_recording_url': voiceRecordingUrl,
        'onboarding_completed': true,
      });

      // Save full profile locally
      await _saveUserLocally(
        uid: uid.value,
        name: name.value.trim(),
        dob: dobString,
        avatarPath: avatarPath.value,
        voiceUrl: voiceRecordingUrl,
      );

      isAuthenticated.value = true;

      return true;
    } catch (e) {
      debugPrint("❌ Onboarding save error: $e");
      Get.snackbar(
        'Error',
        'Failed to complete onboarding',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveUserLocally({
    required String uid,
    required String name,
    required String dob,
    required String avatarPath,
    required String voiceUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uidKey, uid);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_dobKey, dob);
    await prefs.setString(_avatarKey, avatarPath);
    await prefs.setString(_voiceKey, voiceUrl);

    debugPrint("💾 Saved full user profile locally");
  }

  /// Reset onboarding (local only)
  void resetOnboarding() {
    name.value = '';
    dob.value = null;
    avatarPath.value = '';
    voiceRecordingPath.value = '';
    selectedAvatarIndex.value = null;
    isAuthenticated.value = false;
    isCloned.value = false;
    clonedVoiceId.value = '';
    clonedVoiceName.value = '';
  }
}
