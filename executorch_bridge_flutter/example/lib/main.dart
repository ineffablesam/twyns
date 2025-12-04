import 'dart:async';
import 'dart:io';

import 'package:executorch_bridge_flutter/executorch_bridge_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'asset_model_loader.dart';
import 'file_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExecuTorch Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Page')),
      body: Column(
        children: [
          // UnityWidget(
          //   onUnityCreated: (ctl) {
          //     print("Unity Ready");
          //   },
          // ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _executorch = ExecutorchBridge();
  final _messages = <ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _isModelLoaded = false;
  bool _isGenerating = false;
  bool _isLoading = false;
  String _statusMessage = 'No model loaded';
  int _usedMemory = 0;
  int _availableMemory = 0;

  Timer? _memoryTimer;
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _startMemoryMonitoring();
    _errorSubscription = _executorch.errors.listen((error) {
      _showSnackbar('Error: $error', isError: true);
    });
  }

  @override
  void dispose() {
    _memoryTimer?.cancel();
    _errorSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _executorch.dispose();
    super.dispose();
  }

  void _startMemoryMonitoring() {
    _updateMemory();
    _memoryTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateMemory();
    });
  }

  Future<void> _updateMemory() async {
    final memory = await _executorch.getMemoryInfo();
    if (mounted) {
      setState(() {
        _usedMemory = memory.usedMemoryMB;
        _availableMemory = memory.availableMemoryMB;
      });
    }
  }

  Future<void> _loadModelFromAssets() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading model from assets...';
    });

    try {
      final paths = await AssetModelLoader.loadFromAssets(
        modelAssetPath: 'assets/models/llama.pte',
        tokenizerAssetPath: 'assets/models/tokenizer.model',
      );

      await _loadModelWithPaths(paths.modelPath, paths.tokenizerPath);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
      _showSnackbar('Failed to load model: $e', isError: true);
    }
  }

  Future<void> _loadFromDocuments() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Looking for files in Documents...';
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final documentsPath = directory.path;

      print('📁 Documents directory: $documentsPath');

      // List all files in documents directory
      final documentsDir = Directory(documentsPath);
      print('📋 Files in Documents:');
      await for (final entity in documentsDir.list()) {
        print('  - ${entity.path.split('/').last}');
      }

      // Look for .pte and tokenizer files
      String? modelPath;
      String? tokenizerPath;

      await for (final entity in documentsDir.list()) {
        if (entity is File) {
          final fileName = entity.path.split('/').last;
          if (fileName.endsWith('.pte')) {
            modelPath = entity.path;
            print('✅ Found model: $fileName');
          } else if (fileName == 'tokenizer.model' ||
              fileName == 'tokenizer.bin' ||
              fileName == 'tokenizer.json') {
            tokenizerPath = entity.path;
            print('✅ Found tokenizer: $fileName');
          }
        }
      }

      if (modelPath == null) {
        throw Exception('No .pte model file found in Documents directory');
      }
      if (tokenizerPath == null) {
        throw Exception('No tokenizer file found in Documents directory');
      }

      // Validate files exist and are readable
      final modelFile = File(modelPath);
      final tokenizerFile = File(tokenizerPath);

      if (!await modelFile.exists()) {
        throw Exception('Model file does not exist: $modelPath');
      }
      if (!await tokenizerFile.exists()) {
        throw Exception('Tokenizer file does not exist: $tokenizerPath');
      }

      final modelSize = await modelFile.length();
      final tokenizerSize = await tokenizerFile.length();

      print('📊 Model size: $modelSize bytes');
      print('📊 Tokenizer size: $tokenizerSize bytes');

      // Use the persistent paths directly
      await _loadModelWithPaths(modelPath, tokenizerPath);
    } catch (e, stackTrace) {
      print('❌ Error loading from documents: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
      _showSnackbar('Failed to load: $e', isError: true);
    }
  }

  Future<void> _loadModelFromFiles() async {
    try {
      setState(() {
        _statusMessage = 'Selecting model file...';
      });

      // Pick MODEL (.pte)
      final modelResult = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select Model File (.pte)',
        lockParentWindow: true,
      );

      if (modelResult == null || modelResult.files.single.path == null) {
        _showSnackbar('Model selection cancelled');
        return;
      }

      final originalModelPath = modelResult.files.single.path!;
      final modelFileName = modelResult.files.single.name;

      if (!FileHelper.isValidModelFile(modelFileName)) {
        _showSnackbar(
          'Invalid model file. Please select a .pte file',
          isError: true,
        );
        return;
      }

      _showSnackbar('Model selected: $modelFileName');

      // Pick TOKENIZER (.model)
      setState(() {
        _statusMessage = 'Selecting tokenizer file...';
      });

      final tokenizerResult = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select Tokenizer File (.model)',
        lockParentWindow: true,
      );

      if (tokenizerResult == null ||
          tokenizerResult.files.single.path == null) {
        _showSnackbar('Tokenizer selection cancelled');
        return;
      }

      final originalTokenizerPath = tokenizerResult.files.single.path!;
      final tokenizerFileName = tokenizerResult.files.single.name;

      if (!FileHelper.isValidTokenizerFile(tokenizerFileName)) {
        _showSnackbar(
          'Invalid tokenizer file. Please select a .model file',
          isError: true,
        );
        return;
      }

      _showSnackbar('Tokenizer selected: $tokenizerFileName');

      setState(() {
        _isLoading = true;
        _statusMessage = 'Copying files to persistent storage...';
      });

      // CRITICAL FIX: Copy files to persistent Documents directory
      final persistentModelPath = await FileHelper.copyToDocuments(
        originalModelPath,
      );
      final persistentTokenizerPath = await FileHelper.copyToDocuments(
        originalTokenizerPath,
      );

      print('🎯 Using persistent paths:');
      print('   Model: $persistentModelPath');
      print('   Tokenizer: $persistentTokenizerPath');

      // Validate the copied files
      final modelValid = await FileHelper.validateFile(persistentModelPath);
      final tokenizerValid = await FileHelper.validateFile(
        persistentTokenizerPath,
      );

      if (!modelValid || !tokenizerValid) {
        throw Exception('File validation failed after copying');
      }

      setState(() {
        _statusMessage = 'Loading model...';
      });

      // Use the PERSISTENT paths (not the temporary ones)
      await _loadModelWithPaths(persistentModelPath, persistentTokenizerPath);
    } catch (e, stackTrace) {
      print('Error in _loadModelFromFiles: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
      _showSnackbar('Failed to load model: $e', isError: true);
    }
  }

  Future<void> _diagnoseTokenizerFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final documentsPath = directory.path;

      print('\n========================================');
      print('TOKENIZER FILE DIAGNOSTIC');
      print('========================================\n');

      // Find tokenizer file
      final documentsDir = Directory(documentsPath);
      String? tokenizerPath;

      await for (final entity in documentsDir.list()) {
        if (entity is File) {
          final fileName = entity.path.split('/').last;
          if (fileName == 'tokenizer.model' ||
              fileName == 'tokenizer.bin' ||
              fileName == 'tokenizer.json') {
            tokenizerPath = entity.path;
            break;
          }
        }
      }

      if (tokenizerPath == null) {
        print('❌ NO TOKENIZER FILE FOUND');
        print(
          'Expected files: tokenizer.model, tokenizer.bin, or tokenizer.json',
        );
        return;
      }

      final tokenizerFile = File(tokenizerPath);
      final bytes = await tokenizerFile.readAsBytes();
      final extension = tokenizerPath.split('.').last;

      print('📁 File: ${tokenizerPath.split('/').last}');
      print('📊 Size: ${bytes.length} bytes');
      print('🔤 Extension: .$extension\n');

      // Check first 100 bytes
      final first100 = bytes.take(100).toList();
      final hexString = first100
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');

      print('🔍 First 100 bytes (hex):');
      print(hexString);
      print('');

      // Try to interpret as text
      try {
        final asText = String.fromCharCodes(first100);
        print('📝 First 100 bytes (text):');
        print(asText.replaceAll('\n', '\\n'));
        print('');
      } catch (e) {
        print('⚠️  Cannot interpret as text (binary file)');
        print('');
      }

      // Validate format
      print('🔬 FORMAT ANALYSIS:');
      print('─' * 40);

      if (extension == 'json') {
        final firstChar = String.fromCharCode(bytes[0]);
        if (firstChar == '{' || firstChar == '[') {
          print('✅ Valid JSON tokenizer (starts with $firstChar)');
        } else {
          print('❌ INVALID: JSON file should start with { or [');
          print('   This file starts with: $firstChar');
        }
      } else if (extension == 'model' || extension == 'bin') {
        // Check if it's a real SentencePiece model
        // SentencePiece models have specific binary structure
        if (bytes[0] == 0x49 && bytes[1] == 0x51) {
          // Starts with "IQ" - THIS IS WRONG!
          print('❌ INVALID: File appears to be base64-encoded text');
          print('   Real tokenizer.model files are binary, not text');
          print('   Content: IQ== 0, Ig== 1, etc. (base64 encoding)');
          print('');
          print('💡 SOLUTION:');
          print('   You need the REAL binary tokenizer.model file');
          print('   NOT a text file with base64-encoded tokens');
        } else {
          print('ℹ️  Binary file detected');
          print('   First bytes: ${hexString.split(' ').take(20).join(' ')}');
          print('   This might be valid - let native code validate');
        }
      }

      print('\n========================================');
      print('EXPECTED FILE FORMATS:');
      print('========================================');
      print('');
      print('1️⃣ tokenizer.json:');
      print('   - Must be valid JSON');
      print('   - Starts with { or [');
      print('   - Text file, human-readable');
      print('');
      print('2️⃣ tokenizer.model (SentencePiece):');
      print('   - Binary format');
      print('   - NOT text or base64');
      print('   - Created by SentencePiece library');
      print('');
      print('3️⃣ tokenizer.bin:');
      print('   - Binary format');
      print('   - NOT text or base64');
      print('');
      print('❌ INVALID formats:');
      print('   - Text files with "IQ== 0" (base64 encoded)');
      print('   - CSV or text lists of tokens');
      print('   - Corrupted downloads');
      print('');
      print('========================================\n');
    } catch (e, stackTrace) {
      print('Error diagnosing tokenizer: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadModelWithPaths(
    String modelPath,
    String tokenizerPath,
  ) async {
    try {
      setState(() {
        _statusMessage = 'Setting up model (delayed loading)...';
      });

      print('Setting up model with paths:');
      print('Model: $modelPath');
      print('Tokenizer: $tokenizerPath');

      final result = await _executorch.loadModel(
        ModelConfig.llama(modelPath: modelPath, tokenizerPath: tokenizerPath),
      );

      print('Setup result: ${result.success}');
      if (!result.success) {
        print('Setup error: ${result.error}');
        print('Setup message: ${result.message}');
      }

      setState(() {
        _isLoading = false;
        // IMPORTANT: Mark model as "loaded" even though actual loading is delayed
        _isModelLoaded = result.success;
        _statusMessage = result.success
            ? 'Model ready - will load on first generation'
            : 'Failed: ${result.error ?? result.message}';
      });

      if (result.success) {
        _showSnackbar(
          'Model setup completed! Actual loading will happen during first generation.',
        );
      } else {
        _showSnackbar(
          result.error ?? result.message ?? 'Unknown error',
          isError: true,
        );
      }
    } catch (e, stackTrace) {
      print('Error in _loadModelWithPaths: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
      _showSnackbar('Failed to setup model: $e', isError: true);
    }
  }

  void _showLoadModelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _loadFromDocuments();
              },
              icon: const Icon(Icons.folder),
              label: const Text('Load from Documents'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green.shade100,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _loadModelFromAssets();
              },
              icon: const Icon(Icons.folder_special),
              label: const Text('Load from Assets'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _loadModelFromFiles();
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Load from File Picker'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _diagnoseTokenizerFile();
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Diagnose Tokenizer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange.shade100,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isGenerating || !_isModelLoaded) {
      return;
    }

    final prompt = _controller.text.trim();
    _controller.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: prompt, isUser: true, timestamp: DateTime.now()),
      );
      _messages.add(
        ChatMessage(
          text: 'Loading model...',
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: true,
        ),
      );
      _isGenerating = true;
    });

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 100));

    print('🎯 ==================== FLUTTER GENERATING ====================');
    print('🎯 Prompt: "$prompt"');
    print('🎯 Model loaded: $_isModelLoaded');

    final stream = _executorch.generateText(
      prompt,
      config: GenerationConfig.llama(
        sequenceLength: 128,
        maximumNewTokens: 512, // ← ADD THIS! Explicitly set max tokens
      ),
    );

    print('🎯 Stream created, listening for tokens...');

    var generatedText = '';
    var lastTokensPerSecond = 0.0;
    var tokenCount = 0;

    try {
      await for (final token in stream) {
        tokenCount++;
        print('🎯 Token $tokenCount received: "${token.text}"');

        generatedText += token.text;
        lastTokensPerSecond = token.tokensPerSecond;

        setState(() {
          _messages.last = ChatMessage(
            text: generatedText,
            isUser: false,
            timestamp: _messages.last.timestamp,
            tokensPerSecond: lastTokensPerSecond,
            isLoading: false,
          );
        });

        _scrollToBottom();
      }

      print('🎯 Generation completed. Total tokens: $tokenCount');
    } catch (e, stackTrace) {
      print('🎯 ❌ Generation error: $e');
      print('Stack trace: $stackTrace');
      _showSnackbar('Generation error: $e', isError: true);

      setState(() {
        _messages.last = ChatMessage(
          text: 'Error: $e',
          isUser: false,
          timestamp: _messages.last.timestamp,
          isLoading: false,
        );
      });
    } finally {
      print('🎯 Setting isGenerating = false');
      setState(() {
        _isGenerating = false;
      });
      print(
        '🎯 ==================== FLUTTER GENERATION FINISHED ====================',
      );
    }
  }

  Future<void> _testSwiftUIBehavior() async {
    print('\n🧪 ==========================================');
    print('🧪 TESTING: Can generation work despite tokenizer error?');
    print('🧪 ==========================================\n');

    try {
      // Attempt generation to see what error we get
      final stream = _executorch.generateText(
        'test',
        config: GenerationConfig.llama(
          sequenceLength: 128,
          maximumNewTokens: 10, // Set this explicitly!
        ),
      );

      print('🧪 Stream created, waiting for tokens...');

      var tokenCount = 0;
      await for (final token in stream) {
        tokenCount++;
        print('🧪 Token $tokenCount: "${token.text}"');

        if (tokenCount >= 3) {
          print('🧪 Got tokens! Generation is working!');
          break;
        }
      }

      if (tokenCount == 0) {
        print('🧪 ❌ No tokens received');
      }
    } catch (e, stackTrace) {
      print('🧪 ❌ Generation failed with error:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  void _stopGeneration() {
    _executorch.stopGeneration();
    setState(() {
      _isGenerating = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExecuTorch LLM'),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                child: Text('Memory: $_usedMemory MB'),
              ),
              PopupMenuItem<String>(
                enabled: false,
                child: Text('Available: $_availableMemory MB'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'load',
                enabled: !_isLoading && !_isModelLoaded,
                child: const Text('Load Model'),
              ),
              PopupMenuItem<String>(
                value: 'unload',
                enabled: _isModelLoaded,
                child: const Text('Unload Model'),
              ),
              PopupMenuItem<String>(
                value: 'unload',
                enabled: _isModelLoaded,
                onTap: _isModelLoaded
                    ? () {
                        Navigator.pop(context);
                        _testSwiftUIBehavior();
                      }
                    : null,
                child: const Text('SwiftUI Test Model'),
              ),
              //
            ],
            onSelected: (value) {
              if (value == 'load') {
                _showLoadModelDialog();
              } else if (value == 'unload') {
                _executorch.unloadModel();
                setState(() {
                  _isModelLoaded = false;
                  _statusMessage = 'Model unloaded';
                  _messages.clear();
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // In your build method, update the status container:
          Container(
            padding: const EdgeInsets.all(8),
            color: _isModelLoaded
                ? Colors
                      .blue
                      .shade50 // Changed from green to blue to indicate "ready but not loaded"
                : Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  _isModelLoaded
                      ? Icons.check_circle_outline
                      : Icons.info_outline, // Changed icon
                  color: _isModelLoaded ? Colors.blue : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isModelLoaded
                        ? 'Model ready - will load on first message'
                        : _statusMessage,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isModelLoaded
                              ? 'Start a conversation'
                              : 'Load a model to begin',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        if (!_isModelLoaded) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showLoadModelDialog,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Load Model'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Note: Model will load when you send your first message',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(message: _messages[index]);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _isModelLoaded
                          ? 'Type a message...'
                          : 'Load model first',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    enabled: _isModelLoaded && !_isGenerating,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isGenerating ? _stopGeneration : _sendMessage,
                  icon: Icon(_isGenerating ? Icons.stop : Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: _isGenerating
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final double? tokensPerSecond;
  final bool isLoading; // Add this

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.tokensPerSecond,
    this.isLoading = false, // Default to false
  });
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: message.isLoading
                  ? Colors.orange.shade100
                  : Colors.blue.shade100,
              child: Icon(
                message.isLoading ? Icons.hourglass_bottom : Icons.smart_toy,
                color: message.isLoading ? Colors.orange : Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: message.isLoading
                        ? Colors.orange.shade100
                        : message.isUser
                        ? Colors.blue
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: message.isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              message.text,
                              style: TextStyle(color: Colors.orange.shade800),
                            ),
                          ],
                        )
                      : message.text.isEmpty
                      ? const SizedBox(
                          width: 40,
                          height: 20,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Text(
                          message.text,
                          style: TextStyle(
                            color: message.isUser
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                ),
                if (message.tokensPerSecond != null &&
                    message.tokensPerSecond! > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${message.tokensPerSecond!.toStringAsFixed(1)} tokens/s',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
