import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:twyns/modules/pulse/models/pulse_message.dart';

class PulseChatController extends GetxController {
  final messages = <PulseMessage>[].obs;
  final scrollController = ScrollController();

  String? currentStreamingMessageId;
  String? currentTemporaryMessageId;

  @override
  void onInit() {
    super.onInit();
    debugPrint('🎯 PulseChatController initialized');
  }

  void addTemporaryMessage(String text) {
    debugPrint('📨 Adding temporary message: $text');

    // Remove any existing temporary message
    if (currentTemporaryMessageId != null) {
      messages.removeWhere((msg) => msg.id == currentTemporaryMessageId);
    }

    if (text.trim().isEmpty) return;

    currentTemporaryMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final tempMessage = PulseMessage(
      id: currentTemporaryMessageId!,
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      isTemporary: true,
    );

    messages.insert(0, tempMessage);
    debugPrint('✅ Temporary message added. Total messages: ${messages.length}');
    _scrollToBottom();
  }

  void cancelTemporaryMessage() {
    debugPrint('❌ Canceling temporary message');
    if (currentTemporaryMessageId != null) {
      messages.removeWhere((msg) => msg.id == currentTemporaryMessageId);
      currentTemporaryMessageId = null;
    }
  }

  void confirmMessage(String finalText) {
    debugPrint('✅ Confirming message: $finalText');

    // Remove temporary message
    if (currentTemporaryMessageId != null) {
      messages.removeWhere((msg) => msg.id == currentTemporaryMessageId);
      currentTemporaryMessageId = null;
    }

    if (finalText.trim().isEmpty) {
      debugPrint('⚠️ Final text is empty, not adding message');
      return;
    }

    // Add confirmed user message
    final userMessage = PulseMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: finalText.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    messages.insert(0, userMessage);
    debugPrint('✅ Message confirmed. Total messages: ${messages.length}');
    _scrollToBottom();
  }

  void startAIResponse() {
    debugPrint('🤖 Starting AI response');
    currentStreamingMessageId = '${DateTime.now().millisecondsSinceEpoch}_ai';

    final aiMessage = PulseMessage(
      id: currentStreamingMessageId!,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    messages.insert(0, aiMessage);
    debugPrint('✅ AI message placeholder added');
    _scrollToBottom();
  }

  void updateAIResponse(String text) {
    if (currentStreamingMessageId == null) {
      debugPrint('⚠️ No streaming message ID');
      return;
    }

    final index = messages.indexWhere((m) => m.id == currentStreamingMessageId);
    if (index != -1) {
      messages[index] = messages[index].copyWith(text: text);
      _scrollToBottom();
    } else {
      debugPrint(
        '⚠️ Could not find streaming message with ID: $currentStreamingMessageId',
      );
    }
  }

  void finishAIResponse() {
    debugPrint('✅ Finishing AI response');

    if (currentStreamingMessageId == null) return;

    final index = messages.indexWhere((m) => m.id == currentStreamingMessageId);
    if (index != -1) {
      messages[index] = messages[index].copyWith(isStreaming: false);
    }

    currentStreamingMessageId = null;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void clearChat() {
    debugPrint('🗑️ Clearing chat');
    messages.clear();
    currentStreamingMessageId = null;
    currentTemporaryMessageId = null;
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
