package com.twyns.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register the Pigeon API implementation
        val gemmaApi = GemmaApiImpl(context, flutterEngine)
        GemmaApi.setUp(flutterEngine.dartExecutor.binaryMessenger, gemmaApi)
    }
}