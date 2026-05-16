<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    
    <title>@yield('title', 'SDIT AL-FAHMI PALU') - Hadirin</title>
    
    <!-- PWA & Mobile Meta -->
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
    <meta name="theme-color" content="#005147" />
    <meta name="mobile-web-app-capable" content="yes" />
    <meta name="format-detection" content="telephone=no" />

    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet" />

    <!-- Lucide Icons -->
    <script src="https://unpkg.com/lucide@latest"></script>

    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    <!-- SweetAlert2 -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <!-- Hadirin CSS -->
    <link rel="stylesheet" href="{{ asset('css/hadirin.css') }}">
    
    @stack('styles')
</head>
<body class="is-loggedin">
    
    <div id="app-container">
        <!-- MOBILE HEADER -->
        <header class="mobile-header">
            <div class="mobile-header-brand">
                <div class="mobile-header-icon">
                    <span>S</span>
                </div>
                <div class="mobile-header-title">
                    <div class="mobile-header-name">{{ auth()->user()->tenant->name ?? 'Instansi' }}</div>
                    <div class="mobile-header-sub">Dashboard Kehadiran</div>
                </div>
            </div>
            <div class="mobile-header-avatar" onclick="document.getElementById('logout-form').submit();" title="Keluar">
                <i data-lucide="log-out" style="width:16px;height:16px;"></i>
            </div>
        </header>

        <!-- SIDEBAR -->
        <aside id="sidebar" class="glass">
            <div class="logo" style="font-size: 1.5rem; margin-bottom: 40px; text-align: left">
                {{ auth()->user()->tenant->name ?? 'Sistem Absensi' }}
            </div>

            <nav style="flex: 1; overflow-y: auto">
                <a class="nav-item {{ request()->routeIs('dashboard') ? 'active' : '' }}" href="{{ route('dashboard') }}">
                    <i data-lucide="layout-dashboard"></i>
                    <span>Dashboard</span>
                </a>
                
                @if(in_array(strtolower(auth()->user()->role), ['admin', 'super admin', 'superadmin']))
                <div style="font-size: 0.7rem; font-weight: 800; color: var(--text-muted); margin: 24px 0 12px 12px; text-transform: uppercase; letter-spacing: 1px;">
                    Admin Area
                </div>
                <!-- Admin Routes -->
                <a class="nav-item {{ request()->routeIs('attendances.index') ? 'active' : '' }}" href="{{ route('attendances.index') }}">
                    <i data-lucide="monitor"></i>
                    <span>Absensi Hari Ini</span>
                </a>
                <a class="nav-item {{ request()->routeIs('users.index') ? 'active' : '' }}" href="{{ route('users.index') }}">
                    <i data-lucide="users"></i>
                    <span>Data Anggota</span>
                </a>
                <a class="nav-item {{ request()->routeIs('leaves.index') ? 'active' : '' }}" href="{{ route('leaves.index') }}">
                    <i data-lucide="check-square"></i>
                    <span>Persetujuan Izin</span>
                </a>
                <a class="nav-item {{ request()->routeIs('activities.index') ? 'active' : '' }}" href="{{ route('activities.index') }}">
                    <i data-lucide="clipboard-list"></i>
                    <span>Jadwal Kegiatan</span>
                </a>
                <a class="nav-item {{ request()->routeIs('reports.monthly') ? 'active' : '' }}" href="{{ route('reports.monthly') }}">
                    <i data-lucide="file-bar-chart"></i>
                    <span>Laporan Absensi</span>
                </a>
                
                <div style="font-size: 0.7rem; font-weight: 800; color: var(--text-muted); margin: 24px 0 12px 12px; text-transform: uppercase; letter-spacing: 1px;">
                    Kegiatan & Keagamaan
                </div>
                <a class="nav-item {{ request()->routeIs('quran.index') ? 'active' : '' }}" href="{{ route('quran.index') }}">
                    <i data-lucide="book-open"></i>
                    <span>Setoran Hafalan</span>
                </a>
                <a class="nav-item {{ request()->routeIs('ngaji.index') ? 'active' : '' }}" href="{{ route('ngaji.index') }}">
                    <i data-lucide="users"></i>
                    <span>Halaqah / Ngaji</span>
                </a>
                <a class="nav-item {{ request()->routeIs('briefings.index') ? 'active' : '' }}" href="{{ route('briefings.index') }}">
                    <i data-lucide="mic"></i>
                    <span>Rapat & Briefing</span>
                </a>

                <div style="font-size: 0.7rem; font-weight: 800; color: var(--text-muted); margin: 24px 0 12px 12px; text-transform: uppercase; letter-spacing: 1px;">
                    Pengaturan
                </div>
                <a class="nav-item {{ request()->routeIs('office-config.index') ? 'active' : '' }}" href="{{ route('office-config.index') }}">
                    <i data-lucide="settings"></i>
                    <span>Setelan Kantor</span>
                </a>
                <a class="nav-item {{ request()->routeIs('banners.index') ? 'active' : '' }}" href="{{ route('banners.index') }}">
                    <i data-lucide="megaphone"></i>
                    <span>Pengumuman</span>
                </a>
                @else
                <div style="font-size: 0.7rem; font-weight: 800; color: var(--text-muted); margin: 24px 0 12px 12px; text-transform: uppercase; letter-spacing: 1px;">
                    Personal Area
                </div>
                <a class="nav-item {{ request()->routeIs('attendances.history') ? 'active' : '' }}" href="{{ route('attendances.history') }}">
                    <i data-lucide="history"></i>
                    <span>Riwayat Absen</span>
                </a>
                <a class="nav-item {{ request()->routeIs('leaves.personal') ? 'active' : '' }}" href="{{ route('leaves.personal') }}">
                    <i data-lucide="calendar-plus"></i>
                    <span>Ajukan Izin</span>
                </a>
                <a class="nav-item {{ request()->routeIs('quran.create') ? 'active' : '' }}" href="{{ route('quran.create') }}">
                    <i data-lucide="book-open"></i>
                    <span>Setoran Quran</span>
                </a>
                <a class="nav-item {{ request()->routeIs('ngaji.create') ? 'active' : '' }}" href="{{ route('ngaji.create') }}">
                    <i data-lucide="users"></i>
                    <span>Presensi Ngaji</span>
                </a>
                <a class="nav-item {{ request()->routeIs('briefings.personal') ? 'active' : '' }}" href="{{ route('briefings.personal') }}">
                    <i data-lucide="mic"></i>
                    <span>Jadwal Rapat</span>
                </a>
                @endif
            </nav>

            <div class="user-info" style="margin-top: auto; padding: 20px 0; border-top: 1px solid var(--glass-border);">
                <div style="display: flex; align-items: center; gap: 12px">
                    <div style="width: 44px; height: 44px; border-radius: 14px; background: var(--primary-gradient); display: flex; align-items: center; justify-content: center; color: white;">
                        <i data-lucide="user"></i>
                    </div>
                    <div style="overflow: hidden">
                        <div id="user-name" style="font-weight: 800; font-size: 0.95rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; color: var(--text-main);">
                            {{ auth()->user()->name ?? 'User Name' }}
                        </div>
                        <div id="user-id-display" style="font-size: 0.75rem; color: var(--text-muted); font-weight: 600;">
                            ID: {{ auth()->user()->employee_id ?? '-' }}
                        </div>
                    </div>
                </div>
                
                <form id="logout-form" action="{{ route('logout') }}" method="POST" style="display: none;">
                    @csrf
                </form>

                <button class="btn" style="width: 100%; margin-top: 10px; color: #ef4444; background: rgba(239, 68, 68, 0.05); font-size: 0.85rem; padding: 12px;" onclick="document.getElementById('logout-form').submit();">
                    <i data-lucide="log-out" style="width: 16px"></i> Keluar
                </button>
            </div>
        </aside>

        <!-- MAIN CONTENT -->
        <main id="main-content">
            @if(session('success'))
                <script>
                    document.addEventListener('DOMContentLoaded', function() {
                        Swal.fire('Sukses', "{{ session('success') }}", 'success');
                    });
                </script>
            @endif
            @if(session('error'))
                <script>
                    document.addEventListener('DOMContentLoaded', function() {
                        Swal.fire('Error', "{{ session('error') }}", 'error');
                    });
                </script>
            @endif

            @yield('content')
        </main>
    </div>

    <script>
        // Initialize Lucide icons
        lucide.createIcons();
    </script>
    @stack('scripts')
</body>
</html>
