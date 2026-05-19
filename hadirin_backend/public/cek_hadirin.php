<?php
// cek_hadirin.php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

echo "<html><head><title>System Check - Hadirin</title>";
echo "<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; padding: 30px; background: #0f172a; color: #cbd5e1; } 
    .card { background: #1e293b; border-radius: 12px; padding: 25px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); max-width: 800px; margin: 0 auto; border: 1px solid #334155; }
    h1 { color: #f8fafc; border-bottom: 2px solid #334155; padding-bottom: 15px; margin-top: 0; font-size: 24px; }
    h2 { color: #38bdf8; font-size: 18px; margin-top: 25px; }
    .status { padding: 8px 12px; border-radius: 6px; font-weight: bold; display: inline-block; font-size: 14px; }
    .success { background: #064e3b; color: #34d399; }
    .fail { background: #7f1d1d; color: #f87171; }
    .info { color: #94a3b8; font-family: monospace; font-size: 13px; background: #0f172a; padding: 10px; border-radius: 6px; border: 1px solid #1e293b; margin-top: 5px; }
    .btn { display: inline-block; background: #0284c7; color: #fff; padding: 10px 20px; border-radius: 6px; text-decoration: none; font-weight: bold; margin-top: 20px; transition: background 0.2s; }
    .btn:hover { background: #0369a1; }
    pre { background: #0f172a; padding: 15px; border-radius: 6px; border: 1px solid #334155; overflow-x: auto; color: #f8fafc; font-family: 'Consolas', monospace; white-space: pre-wrap !important; word-break: break-all; }
</style>";
echo "</head><body>";
echo "<div class='card'>";
echo "<h1>Diagnostic System - Hadirin Backend</h1>";

echo "<h2>1. Environment & PHP Info</h2>";
echo "PHP Version: <span class='status success'>" . phpversion() . "</span> (Sangat cocok untuk Laravel 11)<br>";
echo "Server Software: " . htmlspecialchars($_SERVER['SERVER_SOFTWARE'] ?? 'Unknown') . "<br>";

// Cek folder utama
$baseDir = dirname(__DIR__);
echo "Base Directory: <div class='info'>$baseDir</div>";

echo "<h2>2. Keberadaan File Utama Laravel</h2>";

// Cek vendor/autoload.php
$autoload = $baseDir . '/vendor/autoload.php';
echo "File <code>vendor/autoload.php</code>: ";
if (file_exists($autoload)) {
    echo "<span class='status success'>Ditemukan!</span><br>";
    echo "<div class='info'>Ukuran file: " . number_format(filesize($autoload)) . " bytes</div>";
} else {
    echo "<span class='status fail'>TIDAK DITEMUKAN!</span><br>";
    echo "<p style='color: #f87171;'><strong>Solusi:</strong> Pastikan folder 'vendor' dari laptop Anda telah diupload seutuhnya ke server via FTP.</p>";
}

        // 2. Cek bootstrap/app.php
        $appPath = $baseDir . '/bootstrap/app.php';
        echo "File <code>bootstrap/app.php</code>: ";
        if (file_exists($appPath)) {
            echo "<span class='status success'>Ditemukan!</span><br>";
        } else {
            echo "<span class='status fail'>TIDAK DITEMUKAN!</span><br>";
        }

        // Audit folder vendor/composer
        echo "<h2>2.1. Audit Composer Autoloader</h2>";
        $composerDir = $baseDir . '/vendor/composer';
        if (is_dir($composerDir)) {
            echo "<span class='status success'>Folder vendor/composer ditemukan!</span><br>";
            $composerFiles = [
                'autoload_real.php',
                'autoload_static.php',
                'autoload_classmap.php',
                'autoload_psr4.php',
                'ClassLoader.php',
                'platform_check.php'
            ];
            echo "<div class='info'><strong>File di vendor/composer:</strong><br>";
            foreach ($composerFiles as $file) {
                $filePath = $composerDir . '/' . $file;
                if (file_exists($filePath)) {
                    echo "- $file: <span style='color:#34d399'>Ada</span> (" . number_format(filesize($filePath)) . " bytes)<br>";
                } else {
                    echo "- $file: <span style='color:#f87171'>TIDAK ADA!</span><br>";
                }
            }
            echo "</div>";
        } else {
            echo "<span class='status fail'>Folder vendor/composer TIDAK DITEMUKAN!</span><br>";
        }

        // Cek bitness PHP
        echo "<h2>2.2. Audit Arsitektur PHP</h2>";
        $bitness = (PHP_INT_SIZE === 8) ? '64-bit' : '32-bit';
        echo "PHP Bitness: <span class='status " . ($bitness === '64-bit' ? 'success' : 'fail') . "'>$bitness</span> (PHP_INT_SIZE = " . PHP_INT_SIZE . ")<br>";
        if ($bitness === '32-bit') {
            echo "<p style='color: #f87171;'><strong>⚠️ PERINGATAN:</strong> Server Anda menggunakan PHP 32-bit. Composer Laravel secara default membuat pengecekan 64-bit di file <code>vendor/composer/platform_check.php</code>. Hal ini akan menyebabkan Laravel langsung crash (Error 500) seketika saat di-load!</p>";
            echo "<p style='color: #38bdf8;'><strong>Solusi:</strong> Hapus file <code>vendor/composer/platform_check.php</code> di server via FTP, atau edit file tersebut dan tambahkan baris <code>&lt;?php return;</code> di bagian paling atas.</p>";
        }



// Cek file .env
$envPath = $baseDir . '/.env';
echo "File <code>.env</code>: ";
if (file_exists($envPath)) {
    echo "<span class='status success'>Ditemukan!</span><br>";
    // Baca baris pertama .env untuk memastikan bisa dibaca
    $lines = file($envPath);
    if (!empty($lines)) {
        echo "<div class='info'>Dapat dibaca. Baris pertama berisi: " . htmlspecialchars(trim($lines[0])) . "</div>";
    } else {
        echo "<div class='info fail'>File .env kosong atau tidak bisa dibaca!</div>";
    }
} else {
    echo "<span class='status fail'>TIDAK DITEMUKAN!</span><br>";
    echo "<p style='color: #f87171;'><strong>Solusi:</strong> Pastikan Anda sudah membuat file <code>.env</code> di server hosting.</p>";
}

echo "<h2>3. Uji Coba Booting Laravel</h2>";
echo "<p>Klik tombol di bawah ini untuk mencoba me-load Laravel dan database secara mendalam:</p>";
echo "<a href='?boot=1' class='btn'>Mulai Booting Test</a>";

if (isset($_GET['boot']) && $_GET['boot'] == '1') {
    echo "<hr style='border: 1px solid #334155; margin-top: 30px;'>";
    echo "<h2>Hasil Deep Booting Test:</h2>";
    
    if (file_exists($autoload) && file_exists($appPath)) {
        try {
            echo "<strong>Langkah 1:</strong> Meload <code>vendor/autoload.php</code>... ";
            flush();
            $loader = require $autoload;
            echo "<span style='color: #34d399;'>Sukses! Autoloader siap digunakan.</span><br>";
            
            echo "<strong>Langkah 2:</strong> Memuat <code>bootstrap/app.php</code>... ";
            flush();
            $app = require_once $appPath;
            echo "<span style='color: #34d399;'>Sukses! Application container siap.</span><br>";
            
            echo "<strong>Langkah 3:</strong> Menginisialisasi HTTP Kernel (Laravel Booting)... ";
            flush();
            $kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
            if (method_exists($kernel, 'bootstrap')) {
                $kernel->bootstrap();
            }
            echo "<span style='color: #34d399;'>Sukses! Laravel berhasil booting sepenuhnya!</span><br>";
            
            echo "<strong>Langkah 4:</strong> Menguji Koneksi Database... ";
            flush();
            $db = $app->make('db');
            $dbName = $db->connection()->getDatabaseName();
            echo "<span style='color: #34d399;'>Sukses! Terhubung ke database: " . htmlspecialchars($dbName) . "</span><br>";

            
            echo "<h3 style='color: #34d399; margin-top: 20px;'>🎉 SEMUA TAHAP BOOTING LARAVEL BERHASIL!</h3>";
            echo "<p>Laravel backend Anda sudah berjalan dengan sempurna di server InfinityFree!</p>";
            echo "<p>Silakan coba jalankan migrasi database menggunakan URL berikut:</p>";
            echo "<a href='run-migrate' class='btn' style='background: #10b981;'>Jalankan Migrasi Database</a>";
            
        } catch (\Throwable $e) {
            echo "<span style='color: #f87171;'>GAGAL!</span><br>";
            echo "<h3>Detail Error:</h3>";
            echo "<pre>Message: " . htmlspecialchars($e->getMessage()) . "\n\nFile: " . $e->getFile() . " (Line " . $e->getLine() . ")\n\nTrace:\n" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
        }
    } else {
        echo "<span class='status fail'>Gagal!</span> File autoload atau app.php tidak lengkap, tidak bisa memulai booting test.";
    }
}



echo "</div>";
echo "</body></html>";
