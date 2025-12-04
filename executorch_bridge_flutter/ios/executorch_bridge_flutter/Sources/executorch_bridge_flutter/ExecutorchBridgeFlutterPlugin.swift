//
//  ExecutorchBridgeFlutterPlugin.swift
//  Runner (Flutter Bridge)
//
//
import Flutter
import UIKit
import ExecuTorchLLM



@objc public class ExecutorchBridgeFlutterPlugin: NSObject, FlutterPlugin, ExecutorchApi {
    // MARK: - Runner Holder (matches SwiftUI app pattern)
    private class RunnerHolder {
        var textRunner: TextRunner?
        var multimodalRunner: MultimodalRunner?

        func reset() {
            textRunner?.reset()
            multimodalRunner?.reset()
        }

        func clear() {
            textRunner = nil
            multimodalRunner = nil
        }
    }

    private let runnerHolder = RunnerHolder()
    private let runnerQueue = DispatchQueue(label: "com.executorch.runner", qos: .userInitiated)
    private var mainQueue = DispatchQueue.main
    private var flutterApi: ExecutorchFlutterApi?
    private var shouldStopGenerating = false
    private var isGenerating = false

    private var conversationHistory: [String] = []

    // Store model config
    private var currentModelPath: String?
    private var currentTokenizerPath: String?
    private var currentModelType: ModelType?
    private var lastPreloadedKey: String?

    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let plugin = ExecutorchBridgeFlutterPlugin()

        ExecutorchApiSetup.setUp(binaryMessenger: messenger, api: plugin)
        plugin.flutterApi = ExecutorchFlutterApi(binaryMessenger: messenger)
    }

    // MARK: - Model Type Detection

    private enum ModelType {
        case gemma3
        case llama
        case llava
        case qwen3
        case phi4
        case smollm3
        case voxtral

        static func fromPath(_ path: String) -> ModelType {
            let filename = (path as NSString).lastPathComponent.lowercased()
            if filename.hasPrefix("gemma3") {
                return .gemma3
            } else if filename.hasPrefix("llama") {
                return .llama
            } else if filename.hasPrefix("llava") {
                return .llava
            } else if filename.hasPrefix("qwen3") {
                return .qwen3
            } else if filename.hasPrefix("phi4") {
                return .phi4
            } else if filename.contains("smollm3") {
                return .smollm3
            } else if filename.hasPrefix("voxtral") {
                return .voxtral
            }
            print("Unknown model type in path: \(path).")
            return .llama
        }
    }

    // MARK: - File Path Debugging

    private func debugFileInfo(_ path: String, label: String) {
        let fileManager = FileManager.default
        let exists = fileManager.fileExists(atPath: path)
        print("=== \(label) DEBUG ===")
        print("Path: \(path)")
        print("Exists: \(exists)")

        if exists {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: path)
                let fileSize = attributes[.size] as? UInt64 ?? 0
                print("File size: \(fileSize) bytes")

                // Read first few bytes to check file type
                if let fileHandle = FileHandle(forReadingAtPath: path) {
                    let data = fileHandle.readData(ofLength: 4)
                    fileHandle.closeFile()

                    let hexString = data.map { String(format: "%02X", $0) }.joined()
                    print("First 4 bytes (hex): \(hexString)")

                    if let string = String(data: data, encoding: .utf8) {
                        print("First 4 bytes (UTF-8): '\(string)'")
                    } else {
                        print("First 4 bytes: Not UTF-8 (likely binary)")
                    }
                }
            } catch {
                print("Error reading file attributes: \(error)")
            }
        }
        print("=================")
    }

    // MARK: - ExecutorchApi Implementation

    func loadModel(config: ModelConfig, completion: @escaping (Result<ModelResponse, Error>) -> Void) {
        runnerQueue.async { [weak self] in
            guard let self = self else {
                completion(.failure(NSError(domain: "ExecutorchBridge", code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "Plugin deallocated"])))
                return
            }

            do {
                guard let modelPath = config.modelPath,
                      let tokenizerPath = config.tokenizerPath else {
                    throw NSError(domain: "ExecutorchBridge", code: -2,
                               userInfo: [NSLocalizedDescriptionKey: "Model or tokenizer path is nil"])
                }

                print("=== Setting up Model ===")

                // Verify files exist
                let fileManager = FileManager.default
                guard fileManager.fileExists(atPath: modelPath) else {
                    throw NSError(domain: "ExecutorchBridge", code: -3,
                               userInfo: [NSLocalizedDescriptionKey: "Model file not found"])
                }

                guard fileManager.fileExists(atPath: tokenizerPath) else {
                    throw NSError(domain: "ExecutorchBridge", code: -4,
                               userInfo: [NSLocalizedDescriptionKey: "Tokenizer file not found"])
                }

                // Store paths
                self.currentModelPath = modelPath
                self.currentTokenizerPath = tokenizerPath
                let modelType = ModelType.fromPath(modelPath)
                self.currentModelType = modelType

                // Check if we need to reload
                let needsReload = self.lastPreloadedKey != (modelPath + "|" + tokenizerPath)
                self.lastPreloadedKey = modelPath + "|" + tokenizerPath

                print("Detected model type: \(modelType)")
                print("Needs reload: \(needsReload)")

                // CRITICAL: Only clear and recreate if paths changed
                if needsReload {
                    print("🔄 Paths changed, clearing runners")
                    self.runnerHolder.clear()
                } else {
                    print("♻️ Reusing existing runner")
                }

                // Create appropriate runner (reuse pattern from SwiftUI)
                switch modelType {
                case .llama:
                    if self.runnerHolder.textRunner == nil {
                        print("Creating TextRunner for Llama")
                        let specialTokens = [
                            "<|begin_of_text|>",
                            "<|end_of_text|>",
                            "<|reserved_special_token_0|>",
                            "<|reserved_special_token_1|>",
                            "<|finetune_right_pad_id|>",
                            "<|step_id|>",
                            "<|start_header_id|>",
                            "<|end_header_id|>",
                            "<|eom_id|>",
                            "<|eot_id|>",
                            "<|python_tag|>"
                        ] + (2..<256).map { "<|reserved_special_token_\($0)|>" }

                        self.runnerHolder.textRunner = TextRunner(
                            modelPath: modelPath,
                            tokenizerPath: tokenizerPath,
                            specialTokens: specialTokens
                        )
                        print("TextRunner created, will load on first generation")
                    } else {
                        print("TextRunner already exists, reusing")
                    }

                case .qwen3, .phi4, .smollm3:
                    if self.runnerHolder.textRunner == nil {
                        print("Creating TextRunner for \(modelType)")
                        self.runnerHolder.textRunner = TextRunner(
                            modelPath: modelPath,
                            tokenizerPath: tokenizerPath
                        )
                    }

                case .llava, .gemma3, .voxtral:
                    if self.runnerHolder.multimodalRunner == nil {
                        print("Creating MultimodalRunner for \(modelType)")
                        self.runnerHolder.multimodalRunner = MultimodalRunner(
                            modelPath: modelPath,
                            tokenizerPath: tokenizerPath
                        )
                    }
                }

                let response = ModelResponse(
                    success: true,
                    error: nil,
                    message: "Model setup completed - will load on first generation",
                    loadTime: nil
                )

                completion(.success(response))

            } catch let error as NSError {
                print("=== Model Setup Failed ===")
                print("Error: \(error.localizedDescription)")

                let response = ModelResponse(
                    success: false,
                    error: error.localizedDescription,
                    message: "Failed to setup model",
                    loadTime: nil
                )
                completion(.success(response))
            }
        }
    }

    // MARK: - Model Loading

    private func loadModelIfNeededSync(reportToUI: Bool) -> Bool {
        guard let modelPath = currentModelPath,
              let tokenizerPath = currentTokenizerPath,
              let modelType = currentModelType else {
            print("❌ Model not configured")
            return false
        }

        print("=== loadModelIfNeededSync ===")
        print("Model type: \(modelType)")

        // Create runner if needed
        switch modelType {
        case .llama:
            if runnerHolder.textRunner == nil {
                let specialTokens = [
                    "<|begin_of_text|>",
                    "<|end_of_text|>",
                    "<|reserved_special_token_0|>",
                    "<|reserved_special_token_1|>",
                    "<|finetune_right_pad_id|>",
                    "<|step_id|>",
                    "<|start_header_id|>",
                    "<|end_header_id|>",
                    "<|eom_id|>",
                    "<|eot_id|>",
                    "<|python_tag|>"
                ] + (2..<256).map { "<|reserved_special_token_\($0)|>" }

                runnerHolder.textRunner = TextRunner(
                    modelPath: modelPath,
                    tokenizerPath: tokenizerPath,
                    specialTokens: specialTokens
                )
            }
        case .qwen3, .phi4, .smollm3:
            if runnerHolder.textRunner == nil {
                runnerHolder.textRunner = TextRunner(
                    modelPath: modelPath,
                    tokenizerPath: tokenizerPath
                )
            }
        case .llava, .gemma3, .voxtral:
            if runnerHolder.multimodalRunner == nil {
                runnerHolder.multimodalRunner = MultimodalRunner(
                    modelPath: modelPath,
                    tokenizerPath: tokenizerPath
                )
            }
        }

        // Try to load
        if (modelType == .llama || modelType == .qwen3 || modelType == .phi4 || modelType == .smollm3),
           let runner = runnerHolder.textRunner {

            if runner.isLoaded() {
                print("✅ TextRunner already loaded")
                return true
            }

            print("⏳ Loading TextRunner...")
            let start = Date()

            do {
                try runner.load()
                let dur = Date().timeIntervalSince(start)
                print("✅ TextRunner loaded in \(String(format: "%.2f", dur))s")
                return true

            } catch let error as NSError {
                let dur = Date().timeIntervalSince(start)
                print("❌ Load threw error after \(String(format: "%.2f", dur))s")
                print("Error code: \(error.code)")

                // CRITICAL FIX: For error code 32 (tokenizer issue),
                // treat as success and try generation anyway (matches SwiftUI behavior)
                if error.code == 32 {
                    print("⚠️ Tokenizer error code 32 - IGNORING and treating as loaded")
                    print("⚠️ This matches SwiftUI app behavior where generation works despite error")
                    // Return TRUE even though load() threw
                    return true
                }

                print("❌ Non-tokenizer error, cannot continue")
                return false
            }

        } else if let runner = runnerHolder.multimodalRunner {

            if runner.isLoaded() {
                print("✅ MultimodalRunner already loaded")
                return true
            }

            print("⏳ Loading MultimodalRunner...")
            let start = Date()

            do {
                try runner.load()
                let dur = Date().timeIntervalSince(start)
                print("✅ MultimodalRunner loaded in \(String(format: "%.2f", dur))s")
                return true

            } catch let error as NSError {
                let dur = Date().timeIntervalSince(start)
                print("❌ Load threw error after \(String(format: "%.2f", dur))s")

                if (error as NSError).code == 32 {
                    print("⚠️ Tokenizer error code 32 - IGNORING and treating as loaded")
                    return true
                }

                return false
            }
        }

        print("❌ No runner available")
        return false
    }

    func isModelLoaded() throws -> Bool {
        let textLoaded = runnerHolder.textRunner?.isLoaded() ?? false
        let multimodalLoaded = runnerHolder.multimodalRunner?.isLoaded() ?? false
        return textLoaded || multimodalLoaded
    }

    func unloadModel() throws {
        runnerQueue.async { [weak self] in
            guard let self = self else { return }
            print("Unloading model...")
            self.runnerHolder.clear()
            self.currentModelPath = nil
            self.currentTokenizerPath = nil
            self.currentModelType = nil
            self.lastPreloadedKey = nil
        }
    }

    // MARK: - Text generation

    func generateText(prompt: String, config: GenerationConfig, completion: @escaping (Result<ModelResponse, Error>) -> Void) {
        runnerQueue.async { [weak self] in
            guard let self = self else { return }

            self.isGenerating = true
            self.shouldStopGenerating = false

            print("=== Starting Generation ===")

            guard let modelType = self.currentModelType else {
                self.mainQueue.async {
                    self.flutterApi?.onError(error: "Model type unknown") { _ in }
                }
                completion(.success(ModelResponse(success: false, error: "Model type unknown", message: nil, loadTime: nil)))
                self.isGenerating = false
                return
            }

            // Try to load if not ready
            let loadSuccess = self.loadModelIfNeededSync(reportToUI: true)

            if !loadSuccess {
                print("❌ Load returned false, but attempting generation anyway...")
                // DON'T RETURN - try generation anyway!
            }

            let sequenceLength = (modelType == .llava || modelType == .gemma3 || modelType == .voxtral) ? 768 : ((modelType == .llama || modelType == .phi4) ? 128 : 768)

            let generationConfig = Config()
            generationConfig.sequenceLength = Int(config.sequenceLength ?? Int64(sequenceLength))
            if let maxTokens = config.maximumNewTokens {
                generationConfig.maximumNewTokens = Int(maxTokens)
            }

            let formatted = self.formattedPromptWithHistory(for: modelType, newPrompt: prompt)


            print("🚀 Attempting generation...")
            print("Runner loaded status: \(self.runnerHolder.textRunner?.isLoaded() ?? false)")

            var tokens: [String] = []
            var tokenCount = 0
            var fullText = ""
            var lastSpeedMeasurement = Date()

            do {
                guard let runner = self.runnerHolder.textRunner else {
                    throw NSError(domain: "ExecutorchBridge", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "No runner available"])
                }

                // CRITICAL: Try generation regardless of isLoaded() status
                // The SwiftUI app does this successfully
                print("📡 Calling runner.generate()...")

                try runner.generate(formatted, generationConfig) { [weak self] token in
                    guard let self = self else { return }

                    if self.shouldStopGenerating {
                        runner.stop()
                        return
                    }

                    print("📨 Token received: '\(token)'")

                    // Filter out prompt echo and stop tokens
                    if token != formatted && !self.isStopToken(token, for: modelType) {
                        tokens.append(token)
                        tokenCount += 1
                        fullText += token

                        // Batch tokens
                        if tokens.count > 2 {
                            let batchText = tokens.joined()
                            tokens.removeAll()

                            let now = Date()
                            let elapsed = now.timeIntervalSince(lastSpeedMeasurement)
                            let speed = elapsed > 0 ? Double(2) / elapsed : 0.0
                            lastSpeedMeasurement = now

                            let tokenData = TokenData(
                                token: batchText,
                                tokenCount: Int64(tokenCount),
                                tokensPerSecond: speed
                            )

                            self.mainQueue.async {
                                self.flutterApi?.onTokenGenerated(token: tokenData) { _ in }
                            }
                        }
                    } else if self.isStopToken(token, for: modelType) {
                        print("🛑 Stop token: '\(token)'")
                        self.shouldStopGenerating = true
                        runner.stop()
                    }
                }

                // Send remaining tokens
                if !tokens.isEmpty {
                    let batchText = tokens.joined()
                    let tokenData = TokenData(
                        token: batchText,
                        tokenCount: Int64(tokenCount),
                        tokensPerSecond: 0.0
                    )
                    self.mainQueue.async {
                        self.flutterApi?.onTokenGenerated(token: tokenData) { _ in }
                    }
                }

                print("✅ Generation completed. Total tokens: \(tokenCount)")

                self.mainQueue.async {
                    self.flutterApi?.onGenerationComplete(fullText: fullText, totalTokens: Int64(tokenCount)) { _ in }
                }

                completion(.success(ModelResponse(success: true, error: nil, message: "Generation completed", loadTime: nil)))

            } catch let error as NSError {
                print("💥 Generation error:")
                print("   Code: \(error.code)")
                print("   Domain: \(error.domain)")
                print("   Description: \(error.localizedDescription)")

                // Check if it's the same tokenizer error during generation
                if error.code == 32 {
                    print("⚠️ This is error code 32 during generation")
                    print("⚠️ SwiftUI app somehow bypasses this - investigating...")
                }

                self.mainQueue.async {
                    self.flutterApi?.onError(error: error.localizedDescription) { _ in }
                }

                completion(.success(ModelResponse(success: false, error: error.localizedDescription, message: nil, loadTime: nil)))
            }

            self.isGenerating = false
//             self.runnerHolder.textRunner?.reset()
        }
    }

    func stopGeneration() throws {
        shouldStopGenerating = true
        print("Stop generation requested")
    }

    func getMemoryInfo() throws -> MemoryInfo {
        let usedMB = usedMemoryInMB()
        let availableMB = availableMemoryInMB()

        return MemoryInfo(
            usedMemoryMB: Int64(usedMB),
            availableMemoryMB: Int64(availableMB)
        )
    }

    func validateFilePath(path: String) throws -> Bool {
        let exists = FileManager.default.fileExists(atPath: path)
        print("Validating file path: \(path) - exists: \(exists)")
        return exists
    }

    // MARK: - Memory Utilities

    private func usedMemoryInMB() -> Int {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        guard kerr == KERN_SUCCESS else { return 0 }
        return Int(info.phys_footprint / 0x100000)
    }

    private func availableMemoryInMB() -> Int {
        return Int(os_proc_available_memory() / 0x100000)
    }

    // MARK: - Helper methods
private func formattedPromptWithHistory(for modelType: ModelType, newPrompt: String) -> String {
    // Append the new prompt to history
    conversationHistory.append(newPrompt)

    // Keep only the last 20 prompts
    if conversationHistory.count > 20 {
        conversationHistory.removeFirst()
    }

    // Combine history into a single prompt
    let historyText = conversationHistory.joined(separator: "\n")

    // Format using existing model-specific template
    return formattedPrompt(for: modelType, rawPrompt: historyText)
}

    private func formattedPrompt(for modelType: ModelType, rawPrompt text: String) -> String {
        switch modelType {
        case .gemma3:
            return String(format: Constants.gemma3PromptTemplate, text)
        case .llama:
            return String(format: Constants.llama3PromptTemplate, text)
        case .llava:
            return String(format: Constants.llavaPromptTemplate, text)
        case .phi4:
            return String(format: Constants.phi4PromptTemplate, text)
        case .qwen3:
            let basePrompt = String(format: Constants.qwen3PromptTemplate, text)
            return basePrompt
        case .smollm3:
            return String(format: Constants.smolLm3PromptTemplate, text)
        case .voxtral:
            return String(format: Constants.voxtralPromptTemplate, text)
        }
    }

    private func isStopToken(_ token: String, for modelType: ModelType) -> Bool {
        switch modelType {
        case .gemma3:
            return token == "<end_of_turn>"
        case .llama:
            return token == "<|eot_id|>" || token == "<|end_of_text|>"
        case .phi4:
            return token == "<|end|>"
        case .qwen3, .smollm3:
            return token == "<|im_end|>"
        case .llava:
            return token == "</s>"
        case .voxtral:
            return false
        }
    }
}
