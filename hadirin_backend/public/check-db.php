<?php
/**
 * Hadirin Database Diagnostics Utility
 * Bypasses bootstrap routing to check database record counts directly.
 */

// Bootstrap Laravel in independent mode to get database access
define('LARAVEL_START', microtime(true));
require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

$diagnostics = [];
$tables_to_check = [
    'tenants' => 'Registered Schools / Tenants',
    'users' => 'Registered Members / Karyawan',
    'office_configs' => 'Office Location Configurations',
    'ngaji_groups' => 'Kelompok Halaqah (Ngaji)',
    'quran_students' => 'Quran Students (Siswa)',
    'quran_masters' => 'Quran Masters (Materi Surah)',
    'verses' => 'Seeded Verses / Ayat Pilihan',
];

$db_connected = false;
$error_message = '';

try {
    DB::connection()->getPdo();
    $db_connected = true;
    
    foreach ($tables_to_check as $table => $desc) {
        $count = DB::table($table)->count();
        $diagnostics[$table] = [
            'desc' => $desc,
            'count' => $count,
            'status' => $count > 0 ? 'success' : 'warning',
            'status_text' => $count > 0 ? "$count Records Found" : "Empty / No Data"
        ];
    }
} catch (\Exception $e) {
    $error_message = $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hadirin Backend - Database Diagnostics</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-color: #080c14;
            --card-bg: rgba(15, 23, 42, 0.75);
            --card-border: rgba(255, 255, 255, 0.08);
            --primary: #8b5cf6;
            --primary-glow: rgba(139, 92, 246, 0.15);
            --success: #10b981;
            --success-glow: rgba(16, 185, 129, 0.15);
            --warning: #f59e0b;
            --warning-glow: rgba(245, 158, 11, 0.15);
            --danger: #ef4444;
            --info: #3b82f6;
            --text-main: #f3f4f6;
            --text-muted: #9ca3af;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
            background-color: var(--bg-color);
            background-image: 
                radial-gradient(circle at 10% 20%, rgba(139, 92, 246, 0.15) 0%, transparent 40%),
                radial-gradient(circle at 90% 80%, rgba(59, 130, 246, 0.1) 0%, transparent 45%);
            background-attachment: fixed;
            color: var(--text-main);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2rem 1rem;
        }

        .container {
            width: 100%;
            max-width: 680px;
        }

        .card {
            background: var(--card-bg);
            border: 1px solid var(--card-border);
            border-radius: 24px;
            padding: 2.5rem;
            backdrop-filter: blur(20px);
            box-shadow: 0 20px 50px rgba(0, 0, 0, 0.4), 
                        0 0 40px var(--primary-glow);
            position: relative;
            overflow: hidden;
        }

        .card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 4px;
            background: linear-gradient(90deg, var(--primary), var(--info));
        }

        .header {
            text-align: center;
            margin-bottom: 2rem;
        }

        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 1.25rem;
            border-radius: 9999px;
            font-size: 0.9rem;
            font-weight: 600;
            margin-bottom: 1.5rem;
        }

        .status-badge.connected {
            background: var(--success-glow);
            color: var(--success);
            border: 1px solid rgba(16, 185, 129, 0.25);
        }

        .status-badge.disconnected {
            background: rgba(239, 68, 68, 0.1);
            color: var(--danger);
            border: 1px solid rgba(239, 68, 68, 0.25);
        }

        h1 {
            font-size: 1.8rem;
            font-weight: 700;
            margin-bottom: 0.5rem;
            background: linear-gradient(to right, #ffffff, #d1d5db);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .subtitle {
            font-size: 0.95rem;
            color: var(--text-muted);
        }

        .grid {
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
            margin-bottom: 2rem;
        }

        .item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 1rem 1.25rem;
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid rgba(255, 255, 255, 0.04);
            border-radius: 16px;
            transition: all 0.3s ease;
        }

        .item:hover {
            background: rgba(255, 255, 255, 0.04);
            border-color: rgba(255, 255, 255, 0.08);
            transform: translateX(4px);
        }

        .info {
            display: flex;
            flex-direction: column;
            gap: 0.25rem;
        }

        .name {
            font-size: 0.95rem;
            font-weight: 600;
            color: #e5e7eb;
        }

        .table-name {
            font-family: monospace;
            font-size: 0.8rem;
            color: var(--text-muted);
        }

        .badge {
            font-size: 0.8rem;
            font-weight: 600;
            padding: 0.35rem 0.75rem;
            border-radius: 9999px;
            display: flex;
            align-items: center;
            gap: 0.35rem;
        }

        .badge-success {
            background: var(--success-glow);
            color: var(--success);
            border: 1px solid rgba(16, 185, 129, 0.20);
        }

        .badge-warning {
            background: var(--warning-glow);
            color: var(--warning);
            border: 1px solid rgba(245, 158, 11, 0.20);
        }

        .badge-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background-color: currentColor;
        }

        .action-area {
            text-align: center;
        }

        .btn-refresh {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.8rem 1.75rem;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            color: var(--text-main);
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.3s ease;
        }

        .btn-refresh:hover {
            background: rgba(255, 255, 255, 0.1);
            border-color: rgba(255, 255, 255, 0.2);
            transform: translateY(-1px);
        }

        .error-card {
            background: rgba(239, 68, 68, 0.05);
            border: 1px solid rgba(239, 68, 68, 0.15);
            padding: 1.5rem;
            border-radius: 16px;
            color: #fca5a5;
            font-size: 0.9rem;
            line-height: 1.5;
            margin-bottom: 2rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="header">
                <?php if ($db_connected): ?>
                    <span class="status-badge connected">● Database Connected</span>
                <?php else: ?>
                    <span class="status-badge disconnected">● Connection Failed</span>
                <?php endif; ?>
                
                <h1>Database Diagnostics</h1>
                <p class="subtitle">Verifies direct record integrity and counts on your production server database.</p>
            </div>

            <?php if (!$db_connected): ?>
                <div class="error-card">
                    <strong>PDO Connection Error:</strong><br>
                    <?php echo htmlspecialchars($error_message); ?>
                </div>
            <?php else: ?>
                <div class="grid">
                    <?php foreach ($diagnostics as $table => $info): ?>
                        <div class="item">
                            <div class="info">
                                <span class="name"><?php echo htmlspecialchars($info['desc']); ?></span>
                                <span class="table-name">Table: <?php echo htmlspecialchars($table); ?></span>
                            </div>
                            <span class="badge badge-<?php echo $info['status']; ?>">
                                <span class="badge-dot"></span>
                                <?php echo htmlspecialchars($info['status_text']); ?>
                            </span>
                        </div>
                    <?php endforeach; ?>
                </div>
            <?php endif; ?>

            <div class="action-area">
                <a href="" class="btn-refresh">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"/></svg>
                    Refresh Status
                </a>
            </div>
        </div>
    </div>
</body>
</html>
