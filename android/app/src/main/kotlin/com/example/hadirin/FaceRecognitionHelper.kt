package com.example.hadirin // Sesuaikan

import android.content.Context
import android.graphics.Bitmap
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel

class FaceRecognitionHelper(context: Context) {
    private var interpreter: Interpreter? = null

    // Nilai default, akan ditimpa secara otomatis oleh model
    private var inputImageSize = 224
    private var outputArraySize = 512

    init {
        val model = loadModelFile(context, "vggface2.tflite")
        val options = Interpreter.Options()
        options.setNumThreads(4)
        interpreter = Interpreter(model, options)

        // ========================================================
        // FITUR BARU: Membaca dimensi model secara otomatis!
        // Ini mencegah crash karena beda ukuran pixel / output
        // ========================================================
        val inputShape = interpreter?.getInputTensor(0)?.shape()
        if (inputShape != null && inputShape.size >= 3) {
            inputImageSize = inputShape[1] // Otomatis menyesuaikan 224 atau 160
        }

        val outputShape = interpreter?.getOutputTensor(0)?.shape()
        if (outputShape != null && outputShape.size >= 2) {
            outputArraySize = outputShape[1] // Otomatis menyesuaikan 512 atau 2048
        }
    }

    private fun loadModelFile(context: Context, modelName: String): MappedByteBuffer {
        val fileDescriptor = context.assets.openFd(modelName)
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }

    fun getFaceEmbedding(bitmap: Bitmap?): FloatArray {
        // Cegah NullPointerException jika foto gagal dibaca
        if (bitmap == null) throw Exception("Bitmap gambar null atau tidak dapat dibaca dari penyimpanan.")

        // 1. Resize gambar ke ukuran model yang otomatis dideteksi
        val resizedBitmap = Bitmap.createScaledBitmap(bitmap, inputImageSize, inputImageSize, true)

        // 2. Siapkan ByteBuffer
        val byteBuffer = ByteBuffer.allocateDirect(1 * inputImageSize * inputImageSize * 3 * 4)
        byteBuffer.order(ByteOrder.nativeOrder())

        // 3. Normalisasi Piksel
        val intValues = IntArray(inputImageSize * inputImageSize)
        resizedBitmap.getPixels(
            intValues, 0, resizedBitmap.width, 0, 0, resizedBitmap.width, resizedBitmap.height
        )
        var pixel = 0
        for (i in 0 until inputImageSize) {
            for (j in 0 until inputImageSize) {
                val valPixel = intValues[pixel++]
                val r = ((valPixel shr 16) and 0xFF)
                val g = ((valPixel shr 8) and 0xFF)
                val b = (valPixel and 0xFF)

                // Standar normalisasi VGGFace
                byteBuffer.putFloat((r - 127.5f) / 128.0f)
                byteBuffer.putFloat((g - 127.5f) / 128.0f)
                byteBuffer.putFloat((b - 127.5f) / 128.0f)
            }
        }

        // 4. Wadah untuk hasil output dengan ukuran dinamis
        val output = Array(1) { FloatArray(outputArraySize) }

        // 5. Jalankan Inference
        interpreter?.run(byteBuffer, output)

        return output[0]
    }

    fun close() {
        interpreter?.close()
    }
}