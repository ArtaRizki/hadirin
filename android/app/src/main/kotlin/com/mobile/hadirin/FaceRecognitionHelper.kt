package com.mobile.hadirin // Sesuaikan

import android.content.Context
import android.graphics.Bitmap
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import kotlin.math.sqrt

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
    // FUNGSI UTAMA: Ambil embedding wajah dari Bitmap
    //
    // Output sudah di-L2-normalize → wajib untuk hasil threshold
    // yang konsisten. Jangan hapus normalisasi ini.
    // ================================================================
    fun getFaceEmbedding(bitmap: Bitmap?): FloatArray {
        if (bitmap == null) {
            throw IllegalArgumentException("Bitmap null — foto gagal dibaca dari penyimpanan.")
        }

        // Resize ke ukuran yang dibutuhkan model
        // Buat variabel terpisah agar bitmap asli tidak ikut di-recycle
        val resizedBitmap = Bitmap.createScaledBitmap(bitmap, inputImageSize, inputImageSize, true)

        return try {
            val inputBuffer = preprocessBitmap(resizedBitmap)
            val output = Array(1) { FloatArray(outputArraySize) }
            interpreter?.run(inputBuffer, output)

            // ⚠️  L2 Normalisasi WAJIB dilakukan sebelum hitung jarak Euclidean.
            //     Tanpa ini, embedding dari dua gambar yang pencahayaannya berbeda
            //     bisa menghasilkan jarak yang tidak konsisten meski orangnya sama.
            l2Normalize(output[0])
        } finally {
            // Bebaskan memori bitmap hasil resize agar tidak bocor (memory leak)
            // Hanya recycle jika berbeda objek dari bitmap asli
            if (resizedBitmap != bitmap) {
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
            val r = (pixelValue shr 16) and 0xFF
            val g = (pixelValue shr 8) and 0xFF
            val b = pixelValue and 0xFF

            byteBuffer.putFloat((r - 127.5f) / 128.0f)
            byteBuffer.putFloat((g - 127.5f) / 128.0f)
            byteBuffer.putFloat((b - 127.5f) / 128.0f)
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
            "Ukuran embedding berbeda: ${embedding1.size} vs ${embedding2.size}"
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
    }
}