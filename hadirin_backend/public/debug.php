<?php
// debug.php - Letakkan di htdocs atau public/
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Matikan output buffering agar setiap echo langsung dikirim ke browser
ob_implicit_flush(true);
if (ob_get_level() > 0) {
    for ($i = 0; $i < ob_get_level(); $i++) {
        ob_end_flush();
    }
}


echo "<html><head><title>Laravel Deployment Debugger</title>";
echo "<style>body { font-family: sans-serif; line-height: 1.6; padding: 20px; background: #f4f6f9; color: #333; } h1 { color: #2c3e50; border-bottom: 2px solid #ccc; padding-bottom: 10px; } .success { color: #27ae60; font-weight: bold; } .fail { color: #c0392b; font-weight: bold; } pre { background: #2c3e50; color: #ecf0f1; padding: 15px; border-radius: 5px; overflow-x: auto; }</style>";
echo "</head><body>";
echo "<h1>Laravel Deployment Debugger</h1>";
echo "<strong>PHP Version:</strong> " . phpversion() . "<br>";

// 1. Cek folder vendor
$autoload = __DIR__.'/../vendor/autoload.php';
if (!file_exists($autoload)) {
    $autoload = __DIR__.'/vendor/autoload.php'; 
}

echo "<strong>Checking vendor/autoload.php:</strong> ";
if (file_exists($autoload)) {
    echo "<span class='success'>Found!</span> ($autoload)<br>";
    try {
        echo "<strong>Attempting to load vendor/autoload.php:</strong> ";
        require $autoload;
        echo "<span class='success'>Success!</span><br>";
        
        // 2. Cek bootstrap/app.php
        $appPath = __DIR__.'/../bootstrap/app.php';
        if (!file_exists($appPath)) {
            $appPath = __DIR__.'/bootstrap/app.php';
        }
        
        echo "<strong>Checking bootstrap/app.php:</strong> ";
        if (file_exists($appPath)) {
            echo "<span class='success'>Found!</span> ($appPath)<br>";
            
            // 3. Cek file .env
            $envPath = __DIR__.'/../.env';
            if (!file_exists($envPath)) {
                $envPath = __DIR__ . '/.env';
            }
            echo "<strong>Checking .env file:</strong> ";
            if (file_exists($envPath)) {
                echo "<span class='success'>Found!</span> ($envPath)<br>";
            } else {
                echo "<span class='fail'>Not Found! (Harap buat file .env di server)</span><br>";
            }

            echo "<strong>Attempting to Boot Laravel:</strong> ";
            $app = require_once $appPath;
            $kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
            echo "<span class='success'>Laravel Booted Successfully!</span><br>";
        } else {
            echo "<span class='fail'>Not Found! Path checked: $appPath</span><br>";
        }
    } catch (\Throwable $e) {
        echo "<span class='fail'>Failed!</span><br>";
        echo "<h3>Error Details:</h3>";
        echo "<pre>Message: " . $e->getMessage() . "\n\nFile: " . $e->getFile() . " (Line " . $e->getLine() . ")\n\nTrace:\n" . $e->getTraceAsString() . "</pre>";
    }
} else {
    echo "<span class='fail'>Not Found! Path checked: $autoload</span><br>";
    echo "<p style='color: #c0392b;'><strong>PENTING:</strong> Folder 'vendor' tidak ditemukan! Pastikan Anda sudah mengupload folder 'vendor' dari laptop Anda ke server via FTP.</p>";
}

echo "</body></html>";
