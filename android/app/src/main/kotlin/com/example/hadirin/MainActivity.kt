package com.example.hadirin // Sesuaikan

import android.graphics.BitmapFactory
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.hadirin/face_recognition"
    private lateinit var faceHelper: FaceRecognitionHelper

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Inisialisasi model
        faceHelper = FaceRecognitionHelper(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "getEmbedding") {
                // Menerima file path gambar dari Flutter
                val imagePath = call.argument<String>("imagePath")
                if (imagePath != null) {
                    try {
                        val bitmap = BitmapFactory.decodeFile(imagePath)
                        val embedding = faceHelper.getFaceEmbedding(bitmap)
                        // Kirim array Float kembali ke Flutter
                        result.success(embedding.toList())
                    } catch (e: Exception) {
                        result.error("ERROR", "Gagal memproses gambar: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID", "Path gambar kosong", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        faceHelper.close()
        super.onDestroy()
    }
}