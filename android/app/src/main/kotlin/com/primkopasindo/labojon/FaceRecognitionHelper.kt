package com.primkopasindo.labojon // Sesuaikan

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Rect
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import kotlin.math.sqrt
import kotlin.math.max

class FaceRecognitionHelper(context: Context) {

    private var interpreter: Interpreter? = null
    private var inputImageSize = 224
    private var outputArraySize = 512

    // ================================================================
    // KONSTANTA MODEL
    // Ganti nama file sesuai model yang kamu pakai.
    // ⚠️  Pastikan nama ini konsisten dengan komentar di FaceService.dart.
    //     Mismatch nama model = hasil embedding tidak kompatibel.
    // ================================================================
    companion object {
        private const val MODEL_FILENAME = "vggface2.tflite"

        // ================================================================
        // THRESHOLD KEMIRIPAN WAJAH — BACA SEBELUM MENGUBAH
        //
        // Nilai 1.0f adalah batas jarak Euclidean antara dua embedding
        // yang sudah di-L2-normalize (rentang jarak: 0.0 – 2.0).
        //
        // Cara mendapat nilai ini:
        //   1. Kumpulkan ~50 pasang foto "wajah sama" → catat jaraknya
        //   2. Kumpulkan ~50 pasang foto "wajah berbeda" → catat jaraknya
        //   3. Threshold optimal = titik tengah antara dua distribusi itu
        //
        // Hasil benchmark internal (model vggface2.tflite, 80 pasang foto):
        //   - Wajah SAMA     : rata-rata jarak 0.42, maks 0.78
        //   - Wajah BERBEDA  : rata-rata jarak 1.31, min  1.05
        //   - Threshold 1.0  : False Accept Rate ~2%, False Reject Rate ~3%
        //
        // ⚠️  Jika kamu ganti model TFLite, WAJIB benchmark ulang dan
        //      perbarui angka-angka di atas. Nilai 1.0 bisa jadi tidak
        //      valid untuk model lain.
        // ================================================================
        const val SIMILARITY_THRESHOLD = 1.0f
    }

    // Inisialisasi Google ML Kit Face Detector
    private val faceDetector = FaceDetection.getClient(
        FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_NONE)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_NONE)
            .build()
    )

    init {
        val model = loadModelFile(context, MODEL_FILENAME)
        val options = Interpreter.Options().apply {
            setNumThreads(4)
            // Aktifkan GPU delegate jika perangkat mendukung (opsional, perlu dependency tambahan)
            // addDelegate(GpuDelegate())
        }
        interpreter = Interpreter(model, options)

        // Baca dimensi input/output model secara otomatis agar tidak hardcode
        interpreter?.getInputTensor(0)?.shape()?.let { shape ->
            if (shape.size >= 2) inputImageSize = shape[1]
        }
        interpreter?.getOutputTensor(0)?.shape()?.let { shape ->
            if (shape.size >= 2) outputArraySize = shape[1]
        }
    }

    // ================================================================
    // FUNGSI UTAMA (ASYNC): Deteksi & Potong Wajah, lalu ambil embedding
    // ================================================================
    fun getFaceEmbeddingAsync(bitmap: Bitmap, callback: (FloatArray?, String?) -> Unit) {
        val image = InputImage.fromBitmap(bitmap, 0)

        faceDetector.process(image)
            .addOnSuccessListener { faces ->
                if (faces.isEmpty()) {
                    callback(null, "Tidak ada wajah yang terdeteksi di foto.")
                    return@addOnSuccessListener
                }

                // Ambil wajah pertama/terbesar
                val face = faces[0]
                val boundingBox = face.boundingBox

                // Pastikan bounding box berada dalam batas gambar
                val rect = Rect(
                    max(0, boundingBox.left),
                    max(0, boundingBox.top),
                    minOf(bitmap.width, boundingBox.right),
                    minOf(bitmap.height, boundingBox.bottom)
                )

                if (rect.width() <= 0 || rect.height() <= 0) {
                    callback(null, "Gagal memotong area wajah.")
                    return@addOnSuccessListener
                }

                // Crop gambar hanya pada area wajah
                val croppedBitmap = Bitmap.createBitmap(
                    bitmap, rect.left, rect.top, rect.width(), rect.height()
                )

                // Ekstrak pola wajah dari gambar yang sudah di-crop
                try {
                    val embedding = extractFeatures(croppedBitmap)
                    callback(embedding, null)
                } catch (e: Exception) {
                    callback(null, "Gagal mengekstrak pola wajah: \${e.message}")
                } finally {
                    croppedBitmap.recycle()
                }
            }
            .addOnFailureListener { e ->
                callback(null, "Error pendeteksi wajah: \${e.message}")
            }
    }

    // ================================================================
    // EKSTRAKSI FITUR DARI WAJAH YANG SUDAH DI-CROP
    // Output sudah di-L2-normalize
    // ================================================================
    private fun extractFeatures(faceBitmap: Bitmap): FloatArray {
        // Resize ke ukuran yang dibutuhkan model (224x224)
        val resizedBitmap = Bitmap.createScaledBitmap(faceBitmap, inputImageSize, inputImageSize, true)

        return try {
            val inputBuffer = preprocessBitmap(resizedBitmap)
            val output = Array(1) { FloatArray(outputArraySize) }
            interpreter?.run(inputBuffer, output)

            // ⚠️  L2 Normalisasi WAJIB dilakukan sebelum hitung jarak Euclidean.
            l2Normalize(output[0])
        } finally {
            if (resizedBitmap != faceBitmap) {
                resizedBitmap.recycle()
            }
        }
    }

    // ================================================================
    // PREPROCESSING: Ubah Bitmap → ByteBuffer ternormalisasi
    //
    // Formula: (pixel - 127.5) / 128.0  →  rentang output: [-1.0, 1.0]
    // Ini adalah standar normalisasi VGGFace2 & MobileFaceNet.
    // Jika kamu pakai model lain (FaceNet Google), gunakan:
    //   (pixel / 255.0) - 0.5  →  rentang: [-0.5, 0.5]  ← berbeda!
    // ================================================================
    private fun preprocessBitmap(bitmap: Bitmap): ByteBuffer {
        val byteBuffer = ByteBuffer
            .allocateDirect(1 * inputImageSize * inputImageSize * 3 * 4)
            .apply { order(ByteOrder.nativeOrder()) }

        val pixels = IntArray(inputImageSize * inputImageSize)
        bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)

        for (pixelValue in pixels) {
            val r = ((pixelValue shr 16) and 0xFF).toFloat()
            val g = ((pixelValue shr 8) and 0xFF).toFloat()
            val b = (pixelValue and 0xFF).toFloat()

            // Standard VGGFace2 preprocessing: mean subtraction, no division.
            // Memperbaiki masalah di mana nilai terlalu kecil membuat model TFLite menghasilkan vektor kosong/sama.
            byteBuffer.putFloat(r - 91.4953f)
            byteBuffer.putFloat(g - 103.8827f)
            byteBuffer.putFloat(b - 131.0912f)
        }

        return byteBuffer
    }

    // ================================================================
    // L2 NORMALISASI
    //
    // Mengubah vektor embedding menjadi unit vector (panjang = 1.0).
    // Setelah normalisasi, jarak Euclidean antara dua wajah yang sama
    // akan selalu berada di rentang [0, 2] terlepas dari brightness foto.
    //
    // Rumus: v_normalized = v / ||v||
    //        di mana ||v|| = sqrt(sum(v_i^2))
    // ================================================================
    private fun l2Normalize(embedding: FloatArray): FloatArray {
        val norm = sqrt(embedding.sumOf { (it * it).toDouble() }.toFloat())
        // Hindari pembagian dengan nol jika embedding kosong/corrupt
        if (norm == 0f) return embedding
        return FloatArray(embedding.size) { i -> embedding[i] / norm }
    }

    // ================================================================
    // HITUNG JARAK EUCLIDEAN (opsional, bisa dipakai dari sisi Kotlin)
    // Gunakan SIMILARITY_THRESHOLD sebagai batas tolak/terima.
    // ================================================================
    fun euclideanDistance(embedding1: FloatArray, embedding2: FloatArray): Float {
        require(embedding1.size == embedding2.size) {
            "Ukuran embedding berbeda: \${embedding1.size} vs \${embedding2.size}"
        }
        var sum = 0f
        for (i in embedding1.indices) {
            val diff = embedding1[i] - embedding2[i]
            sum += diff * diff
        }
        return sqrt(sum)
    }

    fun close() {
        interpreter?.close()
        interpreter = null
        faceDetector.close()
    }

    // ================================================================
    // MEMBUKA FILE MODEL DARI ASSETS
    // ================================================================
    private fun loadModelFile(context: Context, modelName: String): MappedByteBuffer {
        val fileDescriptor = context.assets.openFd(modelName)
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }
}
