<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>Login - SDIT AL-FAHMI PALU</title>
    
    <!-- PWA & Mobile Meta -->
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
    <meta name="theme-color" content="#005147" />

    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet" />

    <!-- Hadirin CSS -->
    <link rel="stylesheet" href="{{ asset('css/hadirin.css') }}">
    <style>
        body { margin: 0; overflow: hidden; }
        #login-screen {
            width: 100%;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            background: radial-gradient(circle at top right, rgba(124, 58, 237, 0.08), transparent),
                        radial-gradient(circle at bottom left, rgba(79, 70, 229, 0.05), transparent);
            background-color: var(--bg-light);
        }
    </style>
</head>
<body>
    <div id="login-screen">
        <div class="card glass login-card">
            <div class="logo" style="margin-bottom: 20px;">
                <img src="{{ asset('images/logo.png') }}" style="height: 100px; width: auto; object-fit: contain;">
                <div style="font-size: 1.5rem; font-weight: 900; background: var(--primary-gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-top: 10px;">
                    SDIT AL-FAHMI PALU
                </div>
            </div>
            <p style="color: var(--text-muted); margin-bottom: 30px; font-weight: 500;">
                Silakan masukkan detail akun untuk mengakses dashboard admin.
            </p>

            @if(session('error'))
                <div style="color: #ef4444; font-size: 0.85rem; margin-bottom: 15px; font-weight: 600; padding: 10px; background: rgba(239, 68, 68, 0.1); border-radius: 8px;">
                    {{ session('error') }}
                </div>
            @endif

            <form action="{{ route('login') }}" method="POST">
                @csrf
                <div class="input-group">
                    <label>Kode Instansi (Client ID)</label>
                    <input type="text" name="client_id" placeholder="CONTOH: INST-123456" required />
                </div>

                <div class="input-group">
                    <label>ID Admin</label>
                    <input type="text" name="employee_id" placeholder="Masukkan ID" required />
                </div>

                <div class="input-group">
                    <label>Password Admin</label>
                    <input type="password" name="password" placeholder="••••••••" required />
                </div>

                <button type="submit" class="btn btn-primary" style="width: 100%; margin-top: 10px;">
                    Masuk Dashboard
                </button>
            </form>
        </div>
    </div>
</body>
</html>
