# ExecuTorch Bridge Flutter

[![pub package](https://img.shields.io/pub/v/executorch_bridge_flutter.svg)](https://pub.dev/packages/executorch_bridge_flutter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)](https://www.apple.com/ios/)
[![Platform](https://img.shields.io/badge/platform-Android-green.svg?logo=android)](https://www.android.com/)

Run AI language models directly on your iPhone or iPad - no internet required! This Flutter plugin lets you add powerful AI chat features to your iOS apps using Meta's ExecuTorch framework.

## What does this do?

This plugin allows you to run Large Language Models (LLMs) like Llama directly on iOS devices. Your users can chat with AI models that work completely offline, keeping their conversations private and fast.

**Perfect for:**
- Private AI assistants that don't send data to servers
- Offline chatbots for apps without internet access
- Fast AI responses without network delays
- Building AI features while protecting user privacy

## Platform Support

| Platform | Supported |
|----------|-----------|
| iOS      | ✅ Yes    |
| Android  | 🚧 Coming soon |
| Web      | ❌ Not planned |
| Desktop  | ❌ Not planned |

> **Note:** Currently only iOS is supported. Android support is actively in development and will be available soon!

## Features

✨ **Run AI models locally** - No server or API keys needed  
🔒 **Complete privacy** - All processing happens on the device  
⚡ **Fast responses** - No network latency  
📱 **Works offline** - Perfect for areas with poor connectivity  
💬 **Real-time streaming** - Get words as they're generated  
📊 **Memory monitoring** - Track how much RAM your model uses  
🎯 **Simple API** - Easy to integrate into your app  

## Requirements

- **iOS:** 14.0 or higher
- **Android:** Coming soon
- **Flutter:** 3.0 or higher
- An ExecuTorch-compatible model file (`.pte` format)
- A tokenizer file (`.model`, `.bin`, or `.json` format)

## iOS Setup

This plugin uses ExecuTorch which is only available via Swift Package Manager. After adding this plugin to your `pubspec.yaml`, you need to:

1. Open your Flutter project's iOS folder in Xcode:
```bash
   open ios/Runner.xcworkspace
```

2. In Xcode, select "File" Menu on the Top Bar

3. Click "Add Package Dependency"

4. Enter the ExecuTorch repository URL:
```
   https://github.com/pytorch/executorch
```

5. Select branch: `swiftpm-1.0.1` or New Version

6. Click "Add Package"

7. Select the following products to add (check all that are required):
    - ✅ executorch_llm_debug
    - ✅ kernels_quantized
    - ✅ kernels_optimized
    - ✅ executorch_debug
    - ✅ backend_xnnpack
    - ✅ kernels_torchao
    - ✅ backend_mps
    - ✅ kernels_llm
    - ✅ backend_coreml
    
8. Click "Add Package"

### Step 2: Configure Linker Flags ⚠️ CRITICAL

**This step is essential** - Without it, ExecuTorch's static libraries won't load properly and tokenizers will fail at runtime.

1. In Xcode, select the "Runner" project (blue icon at top)

2. Select the "Runner" target

3. Go to the "Build Settings" tab

4. Search for "Other Linker Flags" (or scroll to "Linking" section)

5. Find "Other Linker Flags"

6. Add `-all_load` to **both Debug and Release**:
   - Click the "+" button next to "Debug"
   - Enter: `-all_load`
   - Click the "+" button next to "Release"
   - Enter: `-all_load`


12. Clean and rebuild:
```bash
    flutter clean
    flutter pub get
    cd ios && pod install
    cd ..
    flutter run
```

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  executorch_bridge_flutter: ^0.1.1
```

Then run:

```bash
flutter pub get
```

## Getting Your AI Model

Before you can use this plugin, you need two files:

1. **Model file** (`.pte`) - The AI brain
2. **Tokenizer file** (`.model`) - Helps the AI understand text

### Where to get them:

- Download pre-made models from Hugging Face
- Export models using ExecuTorch tools
- Check the [ExecuTorch documentation](https://pytorch.org/executorch/) for conversion guides

> **Note:** Models can be large (500MB - 4GB). Make sure your device has enough storage!

## Quick Start

Here's a simple example to get you chatting with AI:

```dart
import 'package:executorch_bridge_flutter/executorch_bridge_flutter.dart';

// 1. Create the bridge
final executorch = ExecutorchBridge();

// 2. Load your model
final result = await executorch.loadModel(
  ModelConfig.llama(
    modelPath: '/path/to/your/model.pte',
    tokenizerPath: '/path/to/tokenizer.model',
  ),
);

if (result.success) {
  print('Model loaded successfully!');
} else {
  print('Error: ${result.error}');
}

// 3. Generate text
final stream = executorch.generateText(
  'Hello, how are you?',
  config: GenerationConfig.llama(
    sequenceLength: 128,
    maximumNewTokens: 512,
  ),
);

// 4. Get the response word by word
await for (final token in stream) {
  print(token.text); // Prints each word as it's generated
  print('Speed: ${token.tokensPerSecond} tokens/sec');
}
```

## Loading Your Model Files

You have three ways to get model files into your app:

### Option 1: Download from server (✅ RECOMMENDED for production)

This is the best approach because:
- ✅ Keeps your app size small (no huge model files in the bundle)
- ✅ Update models anytime without app updates
- ✅ Download only when needed (saves user bandwidth)
- ✅ Support multiple models without bloating the app

```dart
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

Future<void> downloadAndLoadModel() async {
  final dio = Dio();
  final directory = await getApplicationDocumentsDirectory();
  
  // Download model file
  final modelPath = '${directory.path}/model.pte';
  await dio.download(
    'https://yourserver.com/models/llama-model.pte',
    modelPath,
    onReceiveProgress: (received, total) {
      final progress = (received / total * 100).toStringAsFixed(0);
      print('Downloading model: $progress%');
    },
  );
  
  // Download tokenizer file
  final tokenizerPath = '${directory.path}/tokenizer.model';
  await dio.download(
    'https://yourserver.com/models/tokenizer.model',
    tokenizerPath,
    onReceiveProgress: (received, total) {
      final progress = (received / total * 100).toStringAsFixed(0);
      print('Downloading tokenizer: $progress%');
    },
  );
  
  // Load the downloaded model
  await executorch.loadModel(
    ModelConfig.llama(
      modelPath: modelPath,
      tokenizerPath: tokenizerPath,
    ),
  );
}
```

**Pro tips for server downloads:**
- Cache the files - check if they exist before downloading again
- Show a progress indicator to users during download
- Handle network errors gracefully
- Consider downloading on WiFi only for large models
- Store model version info to enable updates

### Option 2: Bundle with your app (For small models or testing)

Put your model files in `assets/models/` and add to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/model.pte
    - assets/models/tokenizer.model
```

Then load them:

```dart
final paths = await AssetModelLoader.loadFromAssets(
  modelAssetPath: 'assets/models/model.pte',
  tokenizerAssetPath: 'assets/models/tokenizer.model',
);

await executorch.loadModel(
  ModelConfig.llama(
    modelPath: paths.modelPath,
    tokenizerPath: paths.tokenizerPath,
  ),
);
```

⚠️ **Warning:** This will increase your app size significantly!

### Option 3: Let users pick files (For development/testing only)

```dart
import 'package:file_picker/file_picker.dart';

// User selects model file
final modelResult = await FilePicker.platform.pickFiles();
final modelPath = modelResult?.files.single.path;

// User selects tokenizer file
final tokenizerResult = await FilePicker.platform.pickFiles();
final tokenizerPath = tokenizerResult?.files.single.path;

// Load the selected files
await executorch.loadModel(
  ModelConfig.llama(
    modelPath: modelPath!,
    tokenizerPath: tokenizerPath!,
  ),
);
```

## Building a Chat Interface

Here's a complete example of a chat screen:

```dart
class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _executorch = ExecutorchBridge();
  final _controller = TextEditingController();
  final _messages = <String>[];
  bool _isGenerating = false;

  Future<void> _sendMessage() async {
    final prompt = _controller.text;
    _controller.clear();

    setState(() {
      _messages.add('You: $prompt');
      _isGenerating = true;
    });

    var response = '';
    final stream = _executorch.generateText(
      prompt,
      config: GenerationConfig.llama(
        sequenceLength: 128,
        maximumNewTokens: 512,
      ),
    );

    await for (final token in stream) {
      response += token.text;
      setState(() {
        _messages.last = 'AI: $response';
      });
    }

    setState(() {
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_messages[index]));
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                    ),
                    enabled: !_isGenerating,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _isGenerating ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _executorch.dispose();
    super.dispose();
  }
}
```

## Advanced Features

### Monitor Memory Usage

Keep an eye on how much RAM your model is using:

```dart
final memory = await executorch.getMemoryInfo();
print('Used: ${memory.usedMemoryMB} MB');
print('Available: ${memory.availableMemoryMB} MB');
```

### Stop Generation Early

Let users cancel long responses:

```dart
// Start generating
final stream = executorch.generateText('Write a long story...');

// Stop it anytime
executorch.stopGeneration();
```

### Listen for Errors

Handle errors gracefully:

```dart
executorch.errors.listen((error) {
  print('Error occurred: $error');
  // Show error message to user
});
```

### Unload Model

Free up memory when you're done:

```dart
await executorch.unloadModel();
```

## Configuration Options

### Model Configuration

```dart
ModelConfig.llama(
  modelPath: 'path/to/model.pte',      // Required: Your model file
  tokenizerPath: 'path/to/tokenizer',  // Required: Your tokenizer file
)
```

### Generation Configuration

```dart
GenerationConfig.llama(
  sequenceLength: 128,      // Maximum conversation history length
  maximumNewTokens: 512,    // Maximum words to generate
  temperature: 0.7,         // Creativity (0.0 = focused, 1.0 = creative)
  topP: 0.9,               // Response diversity
)
```

## Performance Tips

### Choose the Right Model

- **Smaller models** (1-3GB): Faster, work on older devices, simpler responses
- **Larger models** (4GB+): Slower, need newer devices, smarter responses

### Optimize Settings

- Lower `maximumNewTokens` for faster responses
- Lower `temperature` for more predictable output
- Higher `temperature` for more creative responses

### Memory Management

- Unload models when not in use
- Monitor memory usage regularly
- Test on older devices to ensure compatibility

### Troubleshooting

**Error: "Unable to find module dependency: 'ExecuTorchLLM'"**
- Make sure you've added all 9 required libraries listed in Step 1
- Verify the package was added successfully in Xcode under "Package Dependencies"
- Try cleaning derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`

**Tokenizer crashes at runtime / Symbol not found errors:**
- ⚠️ **Check that `-all_load` is added to Other Linker Flags (Step 2)**
- This is the most common issue - the flag must be present for both Debug and Release
- Clean and rebuild after adding the flag

**Build fails with linker errors:**
- Ensure all 9 libraries are selected and added to your target
- Verify `-all_load` linker flag is present in Build Settings
- Check that your deployment target is iOS 13.0 or higher

**App builds but crashes on launch:**
- Double-check all 9 ExecuTorch libraries are added
- Verify `-all_load` is in Other Linker Flags
- Check Xcode console for specific missing symbol errors

### "Model failed to load"
- Check that your `.pte` file is in ExecuTorch format
- Verify the file path is correct
- Make sure your device has enough free storage

### "Tokenizer error"
- Ensure your tokenizer file matches your model
- Check that the tokenizer file isn't corrupted
- Try re-downloading the tokenizer file

### "Out of memory"
- Use a smaller model
- Close other apps running in the background
- Unload and reload the model to free memory

### Slow generation
- This is normal for large models on older devices
- Consider using a smaller, optimized model
- Lower the `maximumNewTokens` setting

## Example App

Check out the `/example` folder for a complete chat app that demonstrates:
- Loading models from different sources
- Building a chat interface
- Handling errors gracefully
- Monitoring performance
- Managing memory

## Limitations

- **Android support in development** - Currently iOS only, Android coming soon
- **Large files** - Models can be several gigabytes
- **Memory intensive** - Requires devices with sufficient RAM
- **Processing power** - Older devices may be slow

## Contributing

Found a bug? Have a feature request? We'd love your help!

- Report issues on [GitHub Issues](https://github.com/ineffablesam/executorch_bridge_flutter/issues)
- Submit pull requests
- Share your experience and suggestions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Built with:
- [ExecuTorch](https://pytorch.org/executorch/) by Meta
- Flutter team for the amazing framework
- The open source community

## Learn More

- [ExecuTorch Documentation](https://pytorch.org/executorch/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Hugging Face Models](https://huggingface.co/models)

---

Made with ❤️ for the Flutter community. Happy coding!