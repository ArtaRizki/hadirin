<?php
/**
 * Hadirin Cache Purger Utility
 * Bypasses Laravel bootstrap crashes to clean stale config, routes, and package caches on shared hosting.
 */

// Define candidate locations for bootstrap/cache relative to this file
$possible_paths = [
    __DIR__ . '/../bootstrap/cache',
    __DIR__ . '/bootstrap/cache',
    __DIR__ . '/../../bootstrap/cache',
    __DIR__ . '/../hadirin_backend/bootstrap/cache',
];

$cache_dir = null;
foreach ($possible_paths as $path) {
    if (is_dir($path)) {
        $cache_dir = realpath($path);
        break;
    }
}

$files_to_clear = [
    'config.php' => 'Configuration Cache',
    'routes-v7.php' => 'Routes Cache',
    'packages.php' => 'Package Discovery Cache',
    'services.php' => 'Service Provider Cache',
];

$results = [];
$cleared_any = false;
$error_count = 0;

if (isset($_POST['action']) && $_POST['action'] === 'clear') {
    if ($cache_dir) {
        foreach ($files_to_clear as $filename => $description) {
            $filepath = $cache_dir . DIRECTORY_SEPARATOR . $filename;
            if (file_exists($filepath)) {
                if (unlink($filepath)) {
                    $results[$filename] = [
                        'status' => 'success',
                        'message' => 'Successfully deleted.',
                        'desc' => $description
                    ];
                    $cleared_any = true;
                } else {
                    $results[$filename] = [
                        'status' => 'error',
                        'message' => 'Failed to delete. Check file permissions.',
                        'desc' => $description
                    ];
                    $error_count++;
                }
            } else {
                $results[$filename] = [
                    'status' => 'info',
                    'message' => 'File does not exist (already clean).',
                    'desc' => $description
                ];
            }
        }

        // Also clean storage cache manually if possible
        $framework_cache = realpath($cache_dir . '/../../storage/framework/cache/data');
        if ($framework_cache && is_dir($framework_cache)) {
            // Optional: recursive delete could go here, but config/routes is the major culprit
        }
    }
} else {
    // Check initial status
    if ($cache_dir) {
        foreach ($files_to_clear as $filename => $description) {
            $filepath = $cache_dir . DIRECTORY_SEPARATOR . $filename;
            if (file_exists($filepath)) {
                $results[$filename] = [
                    'status' => 'warning',
                    'message' => 'Cache file present. Needs purging.',
                    'desc' => $description
                ];
            } else {
                $results[$filename] = [
                    'status' => 'info',
                    'message' => 'Clean.',
                    'desc' => $description
                ];
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hadirin Backend - Cache Purger Utility</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-color: #0b0f19;
            --card-bg: rgba(17, 24, 39, 0.7);
            --card-border: rgba(255, 255, 255, 0.08);
            --primary: #6366f1;
            --primary-glow: rgba(99, 102, 241, 0.15);
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
                radial-gradient(circle at 10% 20%, rgba(99, 102, 241, 0.15) 0%, transparent 40%),
                radial-gradient(circle at 90% 80%, rgba(16, 185, 129, 0.1) 0%, transparent 45%);
            background-attachment: fixed;
            color: var(--text-main);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2rem 1rem;
            overflow-x: hidden;
        }

        .container {
            width: 100%;
            max-width: 680px;
            perspective: 1000px;
        }

        .card {
            background: var(--card-bg);
            border: 1px solid var(--card-border);
            border-radius: 24px;
            padding: 2.5rem;
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            box-shadow: 0 20px 50px rgba(0, 0, 0, 0.3), 
                        0 0 40px var(--primary-glow);
            transform: translateY(0);
            transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
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
            background: linear-gradient(90deg, var(--primary), var(--success));
        }

        .header {
            text-align: center;
            margin-bottom: 2.5rem;
        }

        .logo-area {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 64px;
            height: 64px;
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 18px;
            margin-bottom: 1rem;
            box-shadow: 0 10px 20px rgba(0, 0, 0, 0.2);
            position: relative;
        }

        .logo-area::after {
            content: '';
            position: absolute;
            inset: -4px;
            border-radius: 22px;
            background: linear-gradient(135deg, var(--primary), var(--success));
            z-index: -1;
            opacity: 0.3;
            filter: blur(8px);
        }

        .logo-icon {
            font-size: 28px;
            font-weight: 700;
            background: linear-gradient(135deg, #a5b4fc, #86efac);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        h1 {
            font-size: 1.8rem;
            font-weight: 700;
            letter-spacing: -0.025em;
            margin-bottom: 0.5rem;
            background: linear-gradient(to right, #ffffff, #d1d5db);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .subtitle {
            font-size: 0.95rem;
            color: var(--text-muted);
            max-width: 460px;
            margin: 0 auto;
            line-height: 1.5;
        }

        /* Server Context Banner */
        .context-banner {
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid rgba(255, 255, 255, 0.05);
            border-radius: 14px;
            padding: 1rem;
            margin-bottom: 2rem;
            font-size: 0.85rem;
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }

        .context-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .context-label {
            color: var(--text-muted);
            font-weight: 500;
        }

        .context-val {
            font-family: monospace;
            color: #d1d5db;
            background: rgba(0, 0, 0, 0.2);
            padding: 0.2rem 0.5rem;
            border-radius: 6px;
            max-width: 70%;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .context-val.success {
            color: var(--success);
            background: var(--success-glow);
        }

        .context-val.danger {
            color: var(--danger);
            background: rgba(239, 68, 68, 0.1);
        }

        /* Files List grid */
        .files-grid {
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
            margin-bottom: 2.5rem;
        }

        .file-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 1rem 1.25rem;
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid rgba(255, 255, 255, 0.04);
            border-radius: 16px;
            transition: all 0.3s ease;
        }

        .file-item:hover {
            background: rgba(255, 255, 255, 0.04);
            border-color: rgba(255, 255, 255, 0.08);
            transform: translateX(4px);
        }

        .file-info {
            display: flex;
            flex-direction: column;
            gap: 0.25rem;
        }

        .file-name {
            font-family: monospace;
            font-size: 0.95rem;
            font-weight: 600;
            color: #e5e7eb;
        }

        .file-desc {
            font-size: 0.8rem;
            color: var(--text-muted);
        }

        .status-badge {
            font-size: 0.8rem;
            font-weight: 600;
            padding: 0.35rem 0.75rem;
            border-radius: 9999px;
            display: flex;
            align-items: center;
            gap: 0.35rem;
        }

        .status-success {
            background: var(--success-glow);
            color: var(--success);
            border: 1px solid rgba(16, 185, 129, 0.2);
        }

        .status-warning {
            background: var(--warning-glow);
            color: var(--warning);
            border: 1px solid rgba(245, 158, 11, 0.2);
        }

        .status-info {
            background: rgba(59, 130, 246, 0.1);
            color: var(--info);
            border: 1px solid rgba(59, 130, 246, 0.2);
        }

        .status-error {
            background: rgba(239, 68, 68, 0.1);
            color: var(--danger);
            border: 1px solid rgba(239, 68, 68, 0.2);
        }

        /* Action form button */
        .btn-container {
            display: flex;
            flex-direction: column;
            gap: 1rem;
            align-items: center;
        }

        .btn {
            width: 100%;
            padding: 1.1rem 2rem;
            background: linear-gradient(135deg, var(--primary) 0%, #4f46e5 100%);
            border: none;
            border-radius: 16px;
            color: #ffffff;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            box-shadow: 0 10px 25px rgba(99, 102, 241, 0.35),
                        inset 0 1px 0 rgba(255, 255, 255, 0.2);
            transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.5rem;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 15px 30px rgba(99, 102, 241, 0.45),
                        0 0 15px rgba(99, 102, 241, 0.2);
            filter: brightness(1.1);
        }

        .btn:active {
            transform: translateY(0);
        }

        .btn:disabled {
            background: #1f2937;
            color: #4b5563;
            box-shadow: none;
            cursor: not-allowed;
            border: 1px solid rgba(255, 255, 255, 0.05);
        }

        .guideline-alert {
            background: rgba(245, 158, 11, 0.05);
            border: 1px solid rgba(245, 158, 11, 0.15);
            border-radius: 16px;
            padding: 1.25rem;
            font-size: 0.85rem;
            line-height: 1.6;
            color: #fcd34d;
            margin-top: 2rem;
            display: flex;
            gap: 0.75rem;
        }

        .guideline-icon {
            font-size: 1.2rem;
            flex-shrink: 0;
        }

        .guideline-text strong {
            color: #ffffff;
        }

        .badge-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background-color: currentColor;
            display: inline-block;
        }

        .anim-pulse {
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% {
                transform: scale(0.95);
                box-shadow: 0 0 0 0 rgba(99, 102, 241, 0.7);
            }
            70% {
                transform: scale(1);
                box-shadow: 0 0 0 10px rgba(99, 102, 241, 0);
            }
            100% {
                transform: scale(0.95);
                box-shadow: 0 0 0 0 rgba(99, 102, 241, 0);
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="header">
                <div class="logo-area">
                    <span class="logo-icon">H</span>
                </div>
                <h1>Cache Purger Utility</h1>
                <p class="subtitle">Directly flushes Laravel configurations and compilation files to resolve application routing, path mismatches, and exception screen loops.</p>
            </div>

            <div class="context-banner">
                <div class="context-row">
                    <span class="context-label">Server Path:</span>
                    <span class="context-val"><?php echo htmlspecialchars(__DIR__); ?></span>
                </div>
                <div class="context-row">
                    <span class="context-label">Bootstrap Cache Folder:</span>
                    <?php if ($cache_dir): ?>
                        <span class="context-val success"><?php echo htmlspecialchars(basename(dirname($cache_dir)) . '/' . basename($cache_dir)); ?></span>
                    <?php else: ?>
                        <span class="context-val danger">Not Found!</span>
                    <?php endif; ?>
                </div>
                <div class="context-row">
                    <span class="context-label">System Mode:</span>
                    <span class="context-val">Independent PHP Execution (Safe Bypass)</span>
                </div>
            </div>

            <form method="POST" action="">
                <input type="hidden" name="action" value="clear">
                
                <div class="files-grid">
                    <?php foreach ($results as $filename => $info): ?>
                        <div class="file-item">
                            <div class="file-info">
                                <span class="file-name"><?php echo htmlspecialchars($filename); ?></span>
                                <span class="file-desc"><?php echo htmlspecialchars($info['desc']); ?></span>
                            </div>
                            <span class="status-badge status-<?php echo $info['status']; ?>">
                                <span class="badge-dot"></span>
                                <?php echo htmlspecialchars($info['message']); ?>
                            </span>
                        </div>
                    <?php endforeach; ?>
                </div>

                <div class="btn-container">
                    <?php if ($cache_dir): ?>
                        <button type="submit" class="btn anim-pulse">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>
                            Purge All Cache Files
                        </button>
                    <?php else: ?>
                        <button type="button" class="btn" disabled>
                            Bootstrap Cache Path Unresolved
                        </button>
                    <?php endif; ?>
                </div>
            </form>

            <div class="guideline-alert">
                <span class="guideline-icon">⚠️</span>
                <div class="guideline-text">
                    <strong>Critical Guideline for Shared Hosting (InfinityFree):</strong><br>
                    Avoid running <code>php artisan optimize</code> or <code>php artisan config:cache</code> on production. These commands serialize absolute physical paths which break on shared environments. Instead, always keep configuration and routing files dynamic, and run only clearing operations.
                </div>
            </div>
        </div>
    </div>
</body>
</html>
