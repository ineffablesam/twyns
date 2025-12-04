package com.twyns.yourapp

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import org.json.JSONObject
import org.pytorch.executorch.extension.llm.LlmCallback
import org.pytorch.executorch.extension.llm.LlmModule
import java.io.File
import java.io.FileOutputStream

class GemmaApiImpl(
  private val context: Context,
  private val flutterEngine: FlutterEngine
) : GemmaApi, LlmCallback {

  private var llmModule: LlmModule? = null
  private var callback: GemmaCallback? = null
  private val generatedTokens = StringBuilder()

  init {
    // Initialize the callback to send results back to Flutter
    GemmaCallback.setUp(flutterEngine.dartExecutor.binaryMessenger, object : GemmaCallback {
      override fun onToken(token: String) {
        // This is called FROM Flutter, not needed here
      }

      override fun onComplete(stats: GenerationStats) {
        // This is called FROM Flutter, not needed here
      }

      override fun onError(error: String) {
        // This is called FROM Flutter, not needed here
      }
    })

    callback = GemmaCallbackProxy(flutterEngine.dartExecutor.binaryMessenger)
  }

  override fun loadModel(config: ModelConfig, callback: (Result<Long>) -> Unit) {
    try {
      // Copy model files from assets to cache if needed
      val modelFile = copyAssetToCacheIfNeeded(config.modelPath)
      val tokenizerFile = copyAssetToCacheIfNeeded(config.tokenizerPath)

      // Load the model using ExecuTorch LLM API (same as the test code)
      llmModule = LlmModule(
        modelFile.absolutePath,
        tokenizerFile.absolutePath,
        config.temperature.toFloat()
      )

      val result = llmModule?.load() ?: -1
      callback(Result.success(result.toLong()))
    } catch (e: Exception) {
      callback(Result.failure(e))
    }
  }

  override fun generate(prompt: String, maxTokens: Long, callback: (Result<String>) -> Unit) {
    try {
      if (llmModule == null) {
        callback(Result.failure(Exception("Model not loaded")))
        return
      }

      generatedTokens.clear()

      // Generate using the LLM module (same API as the test)
      // The onResult and onStats callbacks will be triggered
      llmModule?.generate(prompt, this)

      // Return the complete generated text
      callback(Result.success(generatedTokens.toString()))
    } catch (e: Exception) {
      callback(Result.failure(e))
    }
  }

  override fun stopGeneration() {
    llmModule?.stop()
  }

  override fun unloadModel() {
    llmModule?.stop()
    llmModule = null
  }

  // LlmCallback implementation (called during generation)
  override fun onResult(result: String) {
    // This is called for each generated token
    generatedTokens.append(result)

    // Send token back to Flutter via callback
    callback?.onToken(result) { }
  }

  override fun onStats(result: String) {
    // Parse stats JSON (same as the test code)
    try {
      val jsonObject = JSONObject(result)
      val numGeneratedTokens = jsonObject.getInt("generated_tokens")
      val inferenceEndMs = jsonObject.getInt("inference_end_ms")
      val promptEvalEndMs = jsonObject.getInt("prompt_eval_end_ms")
      val tps = numGeneratedTokens.toFloat() / (inferenceEndMs - promptEvalEndMs) * 1000

      val stats = GenerationStats(
        generatedTokens = numGeneratedTokens.toLong(),
        inferenceEndMs = inferenceEndMs.toLong(),
        promptEvalEndMs = promptEvalEndMs.toLong(),
        tokensPerSecond = tps.toDouble()
      )

      // Send stats back to Flutter
      callback?.onComplete(stats) { }
    } catch (e: Exception) {
      callback?.onError("Failed to parse stats: ${e.message}") { }
    }
  }

  private fun copyAssetToCacheIfNeeded(assetPath: String): File {
    val cacheFile = File(context.cacheDir, assetPath.substringAfterLast('/'))

    if (!cacheFile.exists()) {
      context.assets.open("flutter_assets/$assetPath").use { input ->
        FileOutputStream(cacheFile).use { output ->
          input.copyTo(output)
        }
      }
    }

    return cacheFile
  }
}

// Helper class to send callbacks to Flutter
class GemmaCallbackProxy(
  private val binaryMessenger: io.flutter.plugin.common.BinaryMessenger
) : GemmaCallback {

  private val api = GemmaCallback(binaryMessenger)

  override fun onToken(token: String, callback: (Result<Unit>) -> Unit) {
    api.onToken(token, callback)
  }

  override fun onComplete(stats: GenerationStats, callback: (Result<Unit>) -> Unit) {
    api.onComplete(stats, callback)
  }

  override fun onError(error: String, callback: (Result<Unit>) -> Unit) {
    api.onError(error, callback)
  }
}