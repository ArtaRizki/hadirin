package com.primkopasindo.labojon // Sesuaikan

import android.graphics.BitmapFactory
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.primkopasindo.labojon/face_recognition"
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
                        var bitmap = BitmapFactory.decodeFile(imagePath)
                        if (bitmap == null) {
                            result.error("ERROR", "Gagal membaca file gambar", null)
                            return@setMethodCallHandler
                        }

                        // Perbaiki rotasi dari EXIF (kamera depan sering terbalik)
                        val exif = android.media.ExifInterface(imagePath)
                        val orientation = exif.getAttributeInt(
                            android.media.ExifInterface.TAG_ORIENTATION,
                            android.media.ExifInterface.ORIENTATION_UNDEFINED
                        )
                        val matrix = android.graphics.Matrix()
                        when (orientation) {
                            android.media.ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
                            android.media.ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
                            android.media.ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
                            android.media.ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
                            android.media.ExifInterface.ORIENTATION_FLIP_VERTICAL -> {
                                matrix.postRotate(180f)
                                matrix.postScale(-1f, 1f)
                            }
                        }
                        if (!matrix.isIdentity) {
                            val rotatedBitmap = android.graphics.Bitmap.createBitmap(
                                bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true
                            )
                            bitmap.recycle()
                            bitmap = rotatedBitmap
                        }

                        // Panggil secara asynchronous karena ML Kit butuh waktu
                        faceHelper.getFaceEmbeddingAsync(bitmap) { embedding, errorMsg ->
                            if (embedding != null) {
                                // Kirim array Float kembali ke Flutter
                                result.success(embedding.toList())
                            } else {
                                result.error("ERROR", errorMsg ?: "Wajah tidak terdeteksi", null)
                            }
                        }
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
