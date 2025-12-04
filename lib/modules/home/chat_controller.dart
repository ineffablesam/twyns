import 'dart:async';
import 'dart:io';

import 'package:executorch_bridge_flutter/executorch_bridge_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class ChatController extends GetxController {
  final ExecutorchBridge executorch = ExecutorchBridge();
  final chatController = types.InMemoryChatController();

  // Reactive states
  var isModelLoaded = false.obs;
  var isGenerating = false.obs;
  var isLoadingModel = false.obs;

  var isChatEmpty = true.obs;

  StreamSubscription? _errorSubscription;
  StreamSubscription<types.ChatOperation>? _messagesSub;

  // User IDs
  static const userId = 'user';
  static const assistantId = 'assistant';

  @override
  void onInit() {
    super.onInit();
    _errorSubscription = executorch.errors.listen((error) {
      Get.snackbar(
        'Error',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    });
    // Listen for message changes to update `isChatEmpty`
    _messagesSub = chatController.operationsStream.listen((event) {
      isChatEmpty.value = chatController.messages.isEmpty;
    });
    autoLoadModel();
  }

  @override
  void onClose() {
    _errorSubscription?.cancel();
    executorch.dispose();
    super.onClose();
  }

  // clear chat
  void clearChat() {
    chatController.setMessages([]);
    isChatEmpty.value = true;
  }

  Future<void> autoLoadModel() async {
    isLoadingModel.value = true;
    try {
      final filesExist = await _checkFilesExist();
      if (!filesExist) {
        isLoadingModel.value = false;
        Get.snackbar(
          'Error',
          'Model files not found in Documents/models',
          backgroundColor: Colors.red,
        );
        return;
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final modelDir = '${appDocDir.path}/models';
      final modelPath = '$modelDir/llama-squint.pte';
      final tokenizerPath = '$modelDir/tokenizer.model';

      final result = await executorch.loadModel(
        ModelConfig.llama(modelPath: modelPath, tokenizerPath: tokenizerPath),
      );

      isLoadingModel.value = false;
      isModelLoaded.value = result.success;

      if (result.success) {
        // addSystemMessage('Hi! I\'m ready to chat. Ask me anything!');
      } else {
        Get.snackbar(
          'Error',
          result.error ?? 'Failed to load model',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      isLoadingModel.value = false;
      Get.snackbar(
        'Error',
        'Error loading model: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<bool> _checkFilesExist() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final modelDir = '${appDocDir.path}/models';
      final modelPath = '$modelDir/llama-squint.pte';
      final tokenizerPath = '$modelDir/tokenizer.model';

      return await File(modelPath).exists() &&
          await File(tokenizerPath).exists();
    } catch (e) {
      return false;
    }
  }

  void addSystemMessage(String text) {
    final message = types.Message.text(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: assistantId,
      text: text,
      createdAt: DateTime.now(),
    );

    chatController.insertMessage(message);
  }

  void sendMessage(String message) {
    if (!isModelLoaded.value || isGenerating.value) return;

    final textMessage = types.Message.text(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: userId,
      text: message,
      createdAt: DateTime.now(),
    );

    chatController.insertMessage(textMessage);
    generateResponse(message);
  }

  Future<void> generateResponse(String prompt) async {
    isGenerating.value = true;

    final loadingMessageId = '${DateTime.now().millisecondsSinceEpoch}_loading';
    final createdAt = DateTime.now();

    // Start with empty message
    var currentMessage = types.Message.text(
      id: loadingMessageId,
      authorId: assistantId,
      text: '',
      createdAt: createdAt,
    );

    chatController.insertMessage(currentMessage);

    try {
      final cleanedPrompt = prompt.trimLeft();

      final stream = executorch.generateText(
        cleanedPrompt,
        config: GenerationConfig.llama(
          sequenceLength: 128,
          maximumNewTokens: 512,
        ),
      );

      var generatedText = '';
      bool firstToken = true;

      await for (final token in stream) {
        generatedText += firstToken ? token.text.trimLeft() : token.text;
        firstToken = false;

        print('🔄 Updating message with: $generatedText'); // Debug log

        // Create new message instance with updated text
        final updatedMessage = types.Message.text(
          id: loadingMessageId,
          authorId: assistantId,
          text: generatedText,
          createdAt: createdAt,
        );

        // Update the message
        await chatController.updateMessage(currentMessage, updatedMessage);
        currentMessage = updatedMessage;

        // Force UI update
        isGenerating.refresh();
      }
    } catch (e) {
      print('❌ Error: $e');
      final errorMessage = types.Message.text(
        id: loadingMessageId,
        authorId: assistantId,
        text: 'Sorry, I encountered an error: $e',
        createdAt: createdAt,
      );
      await chatController.updateMessage(currentMessage, errorMessage);
    } finally {
      isGenerating.value = false;
    }
  }
}
