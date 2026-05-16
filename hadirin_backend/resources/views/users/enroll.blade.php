@extends('layouts.app')

@section('title', 'Pendaftaran Wajah')

@push('styles')
<style>
    .camera-container {
        width: 100%;
        max-width: 480px;
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        align-items: center;
        padding: 20px;
    }
    .camera-box {
        width: 100%;
        aspect-ratio: 1/1;
        background: #000;
        border-radius: var(--radius);
        position: relative;
        overflow: hidden;
        border: 4px solid rgba(0, 81, 71, 0.1);
        box-shadow: 0 20px 50px rgba(0, 0, 0, 0.1);
        margin-bottom: 20px;
    }
    #video {
        width: 100%;
        height: 100%;
        object-fit: cover;
        transform: scaleX(-1);
    }
    .overlay {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        display: flex;
        justify-content: center;
        align-items: center;
        pointer-events: none;
    }
    .face-guide {
        width: 60%;
        height: 60%;
        border: 3px dashed rgba(255, 255, 255, 0.5);
        border-radius: 50%;
        box-shadow: 0 0 0 1000px rgba(0, 0, 0, 0.5);
    }
    .scan-line {
        position: absolute;
        top: 20%;
        left: 0;
        width: 100%;
        height: 3px;
        background: #10b981;
        box-shadow: 0 0 15px #10b981;
        animation: scan 3s infinite linear;
    }
    @keyframes scan {
        0% { top: 20%; }
        50% { top: 80%; }
        100% { top: 20%; }
    }
    .status {
        padding: 12px 24px;
        background: rgba(0, 81, 71, 0.1);
        color: var(--primary);
        border-radius: 30px;
        font-weight: 700;
        font-size: 0.9rem;
        text-align: center;
        width: 100%;
        margin-bottom: 20px;
    }
    .status.error {
        background: rgba(239, 68, 68, 0.1);
        color: #ef4444;
    }
    .status.success {
        background: rgba(16, 185, 129, 0.1);
        color: #10b981;
    }
</style>
@endpush

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 20px; text-align: center;">
        <h1 style="font-size: 1.8rem; font-weight: 900; letter-spacing: -0.5px">
            Pendaftaran Wajah
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Arahkan wajah Anda ke dalam lingkaran untuk didaftarkan.
        </p>
    </header>

    <div class="camera-container card glass">
        <div class="camera-box">
            <video id="video" autoplay muted playsinline></video>
            <div class="overlay">
                <div class="face-guide"></div>
                <div class="scan-line" id="scan-line"></div>
            </div>
        </div>

        <div id="status" class="status">Memuat AI Model...</div>

        <button class="btn btn-primary" style="width: 100%; padding: 15px; display: none;" id="btn-submit" onclick="submitEnrollment()">
            Daftarkan Wajah
        </button>
        
        <form id="enroll-form" action="{{ route('users.storeEnrollment') }}" method="POST" style="display: none;">
            @csrf
            <input type="hidden" name="face_descriptor" id="face_descriptor">
        </form>
    </div>
</div>
@endsection

@push('scripts')
<script src="https://cdn.jsdelivr.net/npm/face-api.js@0.22.2/dist/face-api.min.js"></script>
<script>
    const MODEL_URL = "/models";
    const statusEl = document.getElementById('status');
    const video = document.getElementById('video');
    const scanLine = document.getElementById('scan-line');
    const btnSubmit = document.getElementById('btn-submit');
    let scanInterval = null;
    let detectedDescriptor = null;

    async function init() {
        try {
            await faceapi.nets.tinyFaceDetector.loadFromUri(MODEL_URL);
            await faceapi.nets.faceLandmark68Net.loadFromUri(MODEL_URL);
            await faceapi.nets.faceRecognitionNet.loadFromUri(MODEL_URL);
            startCamera();
        } catch (e) {
            statusEl.innerText = "Gagal memuat AI: " + e.message;
            statusEl.className = "status error";
            scanLine.style.display = 'none';
        }
    }

    async function startCamera() {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "user" } });
            video.srcObject = stream;
            video.onplay = () => startScanning();
        } catch (e) {
            statusEl.innerText = "Akses Kamera Ditolak!";
            statusEl.className = "status error";
            scanLine.style.display = 'none';
        }
    }

    function startScanning() {
        statusEl.innerText = "Mendeteksi Wajah...";

        scanInterval = setInterval(async () => {
            const detection = await faceapi
                .detectSingleFace(video, new faceapi.TinyFaceDetectorOptions({ inputSize: 224 }))
                .withFaceLandmarks()
                .withFaceDescriptor();

            if (detection) {
                // If face is found, store descriptor and show button
                clearInterval(scanInterval);
                detectedDescriptor = JSON.stringify(Array.from(detection.descriptor));
                
                statusEl.innerText = "Wajah Terdeteksi Jelas!";
                statusEl.className = "status success";
                scanLine.style.display = 'none';
                btnSubmit.style.display = 'block';
            }
        }, 1000);
    }

    function submitEnrollment() {
        if (!detectedDescriptor) {
            alert("Wajah belum terdeteksi.");
            return;
        }
        statusEl.innerText = "Menyimpan Data...";
        document.getElementById('face_descriptor').value = detectedDescriptor;
        document.getElementById('enroll-form').submit();
    }

    init();
</script>
@endpush
