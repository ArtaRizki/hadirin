<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    
    <title>@yield('title', 'Dashboard') - SDIT AL-FAHMI PALU</title>
    
    <!-- PWA & Mobile Meta -->
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
    <meta name="theme-color" content="#005147" />

    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet" />

    <!-- Hadirin CSS -->
    <link rel="stylesheet" href="{{ asset('css/hadirin.css') }}">
    
    <!-- Lucide Icons -->
    <script src="https://unpkg.com/lucide@latest"></script>

    @yield('styles')
</head>
<body class="is-loggedin">
    <div id="app-container">
        <!-- MOBILE HEADER -->
        <header class="mobile-header">
            <div class="mobile-header-brand">
                <div class="mobile-header-icon">
                    <img src="{{ asset('images/logo.png') }}" style="width: 100%; height: 100%; object-fit: contain;">
                </div>
                <div class="mobile-header-title">
                    <div class="mobile-header-name">{{ auth()->user()->tenant->name ?? 'Instansi' }}</div>
                    <div class="mobile-header-sub">SDIT AL-FAHMI PALU</div>
                </div>
            </div>
            <div class="mobile-header-avatar" onclick="document.getElementById('logout-form').submit();" title="Keluar">
                <i data-lucide="log-out" style="width:16px;height:16px;"></i>
            </div>
        </header>

        <!-- SIDEBAR -->
        <aside id="sidebar" class="glass">
            <div class="logo" style="margin-bottom: 30px; text-align: left">
                <img src="{{ asset('images/logo.png') }}" style="height: 60px; width: auto; object-fit: contain;">
                <div style="font-size: 0.8rem; font-weight: 800; margin-top: 10px; color: var(--primary); line-height: 1.2;">
                    {{ auth()->user()->tenant->name ?? 'Sistem Absensi' }}
                </div>
            </div>

            <nav style="flex: 1; overflow-y: auto">
                <a href="{{ route('dashboard') }}" class="nav-item {{ request()->routeIs('dashboard') ? 'active' : '' }}">
                    <i data-lucide="layout-dashboard"></i> <span>Dashboard</span>
                </a>

                <!-- MENU UNTUK SEMUA -->
                <div style="padding: 15px 20px 5px; font-size: 0.65rem; font-weight: 800; color: var(--text-muted); text-transform: uppercase; letter-spacing: 1px;">Fitur Harian</div>
                
                <a href="{{ route('activities.index') }}" class="nav-item {{ request()->routeIs('activities.*') ? 'active' : '' }}">
                    <i data-lucide="calendar"></i> <span>Kegiatan</span>
                </a>
                <a href="{{ route('quran.index') }}" class="nav-item {{ request()->routeIs('quran.*') ? 'active' : '' }}">
                    <i data-lucide="book-open"></i> <span>Tadarus Guru</span>
                </a>
                <a href="{{ route('ngaji.index') }}" class="nav-item {{ request()->routeIs('ngaji.*') ? 'active' : '' }}">
                    <i data-lucide="mic-2"></i> <span>Halaqah Guru</span>
                </a>
                <a href="{{ route('briefings.index') }}" class="nav-item {{ request()->routeIs('briefings.*') ? 'active' : '' }}">
                    <i data-lucide="users-2"></i> <span>Briefing Harian</span>
                </a>
                <a href="{{ route('leaves.personal') }}" class="nav-item {{ request()->routeIs('leaves.personal') ? 'active' : '' }}">
                    <i data-lucide="file-text"></i> <span>Izin & Cuti</span>
                </a>
                <a href="{{ route('feedback.create') }}" class="nav-item {{ request()->routeIs('feedback.create') ? 'active' : '' }}">
                    <i data-lucide="message-square"></i> <span>Kritik & Saran</span>
                </a>

                @if(auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin')
                    <!-- MENU KHUSUS ADMIN -->
                    <div style="padding: 20px 20px 5px; font-size: 0.65rem; font-weight: 800; color: var(--primary); text-transform: uppercase; letter-spacing: 1px;">Admin Control</div>
                    
                    <a href="{{ route('users.index') }}" class="nav-item {{ request()->routeIs('users.*') ? 'active' : '' }}">
                        <i data-lucide="users"></i> <span>Data Anggota</span>
                    </a>
                    <a href="{{ route('leaves.index') }}" class="nav-item {{ request()->routeIs('leaves.index') ? 'active' : '' }}">
                        <i data-lucide="check-square"></i> <span>Persetujuan Izin</span>
                    </a>
                    <a href="{{ route('reports.monthly') }}" class="nav-item {{ request()->routeIs('reports.*') ? 'active' : '' }}">
                        <i data-lucide="bar-chart-3"></i> <span>Laporan Absensi</span>
                    </a>
                    <a href="{{ route('feedback.index') }}" class="nav-item {{ request()->routeIs('feedback.index') ? 'active' : '' }}">
                        <i data-lucide="inbox"></i> <span>Lihat Masukan</span>
                    </a>
                    <a href="{{ route('positions.index') }}" class="nav-item {{ request()->routeIs('positions.*') ? 'active' : '' }}">
                        <i data-lucide="briefcase"></i> <span>Manajemen Jabatan</span>
                    </a>
                    <a href="{{ route('verses.index') }}" class="nav-item {{ request()->routeIs('verses.*') ? 'active' : '' }}">
                        <i data-lucide="quote"></i> <span>Kelola Ayat</span>
                    </a>
                    <a href="{{ route('banners.index') }}" class="nav-item {{ request()->routeIs('banners.*') ? 'active' : '' }}">
                        <i data-lucide="image"></i> <span>Manajemen Banner</span>
                    </a>
                    <a href="{{ route('office-config.index') }}" class="nav-item {{ request()->routeIs('office-config.*') ? 'active' : '' }}">
                        <i data-lucide="settings"></i> <span>Setelan Kantor</span>
                    </a>
                @endif

                @if(auth()->user()->role != 'admin' && auth()->user()->role != 'superadmin')
                    <a href="https://wa.me/6281234567890" target="_blank" class="nav-item" style="color: #10b981; margin-top: 10px; border: 1px dashed rgba(16, 185, 129, 0.3);">
                        <i data-lucide="phone"></i> <span>Hubungi Pengelola</span>
                    </a>
                @endif
            </nav>

            <!-- USER INFO & LOGOUT -->
            <div class="user-info" style="margin-top: 20px; padding: 15px 0; border-top: 1px solid var(--glass-border);">
                <div style="display: flex; align-items: center; gap: 12px">
                    <div style="width: 38px; height: 38px; border-radius: 10px; background: var(--primary-gradient); display: flex; align-items: center; justify-content: center; color: white;">
                        <i data-lucide="user" style="width:18px;height:18px;"></i>
                    </div>
                    <div style="overflow: hidden">
                        <div style="font-weight: 800; font-size: 0.85rem; color: var(--text-main); white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
                            {{ auth()->user()->name }}
                        </div>
                        <div style="font-size: 0.7rem; color: var(--text-muted); font-weight: 600;">
                            ID: {{ auth()->user()->employee_id }}
                        </div>
                    </div>
                </div>
                <form id="logout-form" action="{{ route('logout') }}" method="POST" style="display: none;">@csrf</form>
                <button onclick="document.getElementById('logout-form').submit();" class="btn" style="width: 100%; margin-top: 12px; height: auto; padding: 10px; font-size: 0.8rem; background: rgba(239, 68, 68, 0.05); color: #ef4444; border: 1px solid rgba(239, 68, 68, 0.1);">
                    <i data-lucide="log-out" style="width: 14px; height: 14px;"></i> Keluar
                </button>
            </div>
        </aside>

        <!-- MAIN CONTENT -->
        <main id="main-content">
            @if(session('success'))
                <div style="padding: 16px 20px; background: #ecfdf5; border: 1px solid #10b981; border-radius: 12px; color: #065f46; font-weight: 600; margin-bottom: 20px; display: flex; align-items: center; gap: 12px;">
                    <i data-lucide="check-circle" style="color: #10b981;"></i>
                    {{ session('success') }}
                </div>
            @endif

            @if(session('error'))
                <div style="padding: 16px 20px; background: #fef2f2; border: 1px solid #ef4444; border-radius: 12px; color: #991b1b; font-weight: 600; margin-bottom: 20px; display: flex; align-items: center; gap: 12px;">
                    <i data-lucide="alert-circle" style="color: #ef4444;"></i>
                    {{ session('error') }}
                </div>
            @endif

            @yield('content')
        </main>

        <!-- MOBILE BOTTOM NAV -->
        <nav class="bottom-nav">
            <a href="{{ route('dashboard') }}" class="bottom-nav-item {{ request()->routeIs('dashboard') ? 'active' : '' }}">
                <i data-lucide="layout-dashboard"></i>
                <span>Beranda</span>
            </a>
            <a href="{{ route('activities.index') }}" class="bottom-nav-item {{ request()->routeIs('activities.*') ? 'active' : '' }}">
                <i data-lucide="calendar"></i>
                <span>Kegiatan</span>
            </a>
            <a href="{{ route('leaves.personal') }}" class="bottom-nav-item {{ request()->routeIs('leaves.personal') ? 'active' : '' }}">
                <i data-lucide="file-text"></i>
                <span>Izin</span>
            </a>
            <a href="{{ route('feedback.create') }}" class="bottom-nav-item {{ request()->routeIs('feedback.create') ? 'active' : '' }}">
                <i data-lucide="message-square"></i>
                <span>Saran</span>
            </a>
        </nav>
    </div>

    <script>
        // Initialize Lucide Icons
        lucide.createIcons();

        // Modal Helpers
        function openModal(id) {
            document.getElementById(id).classList.add('modal-active');
        }
        function closeModal(id) {
            document.getElementById(id).classList.remove('modal-active');
        }
    </script>
    @yield('scripts')
</body>
</html>
