// lib/services/cartesia_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CartesiaService {
  static const String _apiKey = 'sk_car_u3MhNiFyUFJ2prACqwEDxz';
  static const String _baseUrl = 'https://api.cartesia.ai';
  static const String _cartesiaVersion = '2025-04-16';

  /// Clone a voice from audio file
  static Future<Map<String, dynamic>?> cloneVoice({
    required String audioFilePath,
    required String voiceName,
    String? description,
    String language = 'en',
    String? baseVoiceId,
  }) async {
    try {
      debugPrint('🎙️ Starting voice cloning...');
      debugPrint('📁 Audio file path: $audioFilePath');

      final uri = Uri.parse('$_baseUrl/voices/clone');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Cartesia-Version': _cartesiaVersion,
      });

      // Add audio file
      File audioFile;

      // Handle both local files and URLs
      if (audioFilePath.startsWith('http')) {
        debugPrint('📥 Downloading audio from URL...');
        final response = await http.get(Uri.parse(audioFilePath));
        if (response.statusCode != 200) {
          throw Exception('Failed to download audio file');
        }

        // Create temporary file
        final tempDir = Directory.systemTemp;
        final tempFile = File(
          '${tempDir.path}/temp_voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        await tempFile.writeAsBytes(response.bodyBytes);
        audioFile = tempFile;
        debugPrint('✅ Audio downloaded to temp file');
      } else {
        audioFile = File(audioFilePath);
      }

      if (!await audioFile.exists()) {
        throw Exception('Audio file does not exist: $audioFilePath');
      }

      final audioBytes = await audioFile.readAsBytes();
      debugPrint('📦 Audio file size: ${audioBytes.length} bytes');

      request.files.add(
        http.MultipartFile.fromBytes(
          'clip',
          audioBytes,
          filename: 'voice_recording.m4a',
        ),
      );

      // Add form fields
      request.fields['name'] = voiceName;
      request.fields['language'] = language;

      if (description != null) {
        request.fields['description'] = description;
      }

      if (baseVoiceId != null) {
        request.fields['base_voice_id'] = baseVoiceId;
      }

      debugPrint('🚀 Sending request to Cartesia API...');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📨 Response status: ${response.statusCode}');
      debugPrint('📨 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        debugPrint('✅ Voice cloned successfully!');
        debugPrint('🎤 Voice ID: ${data['id']}');
        debugPrint('🎤 Voice Name: ${data['name']}');

        // Clean up temp file if created
        if (audioFilePath.startsWith('http')) {
          await audioFile.delete();
          debugPrint('🗑️ Cleaned up temp file');
        }

        return data;
      } else {
        debugPrint('❌ Voice cloning failed: ${response.statusCode}');
        debugPrint('❌ Error: ${response.body}');
        return null;
      }
    } catch (e, stack) {
      debugPrint('❌ Voice cloning error: $e');
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }

  /// Get voice details by ID
  static Future<Map<String, dynamic>?> getVoice(String voiceId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/voices/$voiceId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Cartesia-Version': _cartesiaVersion,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('❌ Failed to get voice: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Get voice error: $e');
      return null;
    }
  }

  /// Delete a cloned voice
  static Future<bool> deleteVoice(String voiceId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/voices/$voiceId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Cartesia-Version': _cartesiaVersion,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ Voice deleted successfully');
        return true;
      } else {
        debugPrint('❌ Failed to delete voice: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Delete voice error: $e');
      return false;
    }
  }
}
