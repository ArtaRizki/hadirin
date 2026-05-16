@extends('layouts.app')

@section('title', 'Verifikasi Wajah')

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
            Absen {{ request()->type }}
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Arahkan wajah Anda ke dalam lingkaran
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

        <button class="btn btn-primary" style="width: 100%; padding: 15px; display: none;" id="btn-enroll" onclick="window.location.href='{{ route('users.enroll') }}'">
            Daftarkan Wajah Sekarang
        </button>
        
        <form id="absen-form" action="{{ route('attendances.storeWeb') }}" method="POST" style="display: none;">
            @csrf
            <input type="hidden" name="type" value="{{ request()->type }}">
            <input type="hidden" name="lat_long" id="lat_long">
            <input type="hidden" name="photo" id="photo">
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
    let faceMatcher = null;
    let scanInterval = null;

    // Load user face descriptor from DB
    const savedDescriptorRaw = @json(auth()->user()->face_descriptor);

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
        statusEl.innerText = "Memindai Wajah...";

        let isValidDesc = false;
        if (savedDescriptorRaw && savedDescriptorRaw.length > 20) {
            try {
                const parsed = JSON.parse(savedDescriptorRaw);
                if (Array.isArray(parsed) && parsed.length === 128) {
                    const desc = new Float32Array(parsed);
                    faceMatcher = new faceapi.FaceMatcher(
                        new faceapi.LabeledFaceDescriptors('user', [desc]),
                        0.63 // Euclidean Distance ~ 0.63 setara dengan Cosine Similarity ~ 0.8
                    );
                    isValidDesc = true;
                }
            } catch (e) {
                console.error("Parse error", e);
            }
        }

        if (!isValidDesc) {
            statusEl.innerText = "Wajah Belum Terdaftar di Sistem";
            statusEl.className = "status error";
            document.getElementById('btn-enroll').style.display = 'block';
            scanLine.style.display = 'none';
            return;
        }

        scanInterval = setInterval(async () => {
            const detection = await faceapi
                .detectSingleFace(video, new faceapi.TinyFaceDetectorOptions({ inputSize: 224 }))
                .withFaceLandmarks()
                .withFaceDescriptor();

            if (detection && faceMatcher) {
                const match = faceMatcher.findBestMatch(detection.descriptor);
                if (match.label !== "unknown") {
                    clearInterval(scanInterval);
                    statusEl.innerText = "Wajah Dikenali! Mengambil Lokasi...";
                    statusEl.className = "status success";
                    scanLine.style.display = 'none';
                    processAttendance();
                } else {
                    statusEl.innerText = "Wajah Tidak Dikenali";
                    statusEl.className = "status error";
                }
            }
        }, 1000);
    }

    function processAttendance() {
        // Ambil Foto Base64
        const canvas = document.createElement("canvas");
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        canvas.getContext("2d").drawImage(video, 0, 0);
        document.getElementById('photo').value = canvas.toDataURL("image/jpeg", 0.6).split(",")[1];

        // Dapatkan Lokasi GPS
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (pos) => {
                    document.getElementById('lat_long').value = pos.coords.latitude + "," + pos.coords.longitude;
                    statusEl.innerText = "Mengirim Data Absensi...";
                    document.getElementById('absen-form').submit();
                },
                (err) => {
                    alert("Akses lokasi dibutuhkan untuk absen!");
                    statusEl.innerText = "Gagal Mendapatkan Lokasi";
                    statusEl.className = "status error";
                },
                { enableHighAccuracy: true, timeout: 10000 }
            );
        } else {
            alert("Geolocation tidak didukung di browser ini.");
        }
    }

    init();
</script>
@endpush
