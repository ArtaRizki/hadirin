@extends('layouts.app')

@section('title', 'Dashboard')

@section('content')
<div class="content-view">
    <header style="margin-bottom: 30px;">
        <h1 style="font-size: 2.2rem; font-weight: 900; color: var(--text-main); letter-spacing: -1px;">Dashboard Kehadiran</h1>
        <p style="color: var(--text-muted); font-weight: 500;">Selamat datang kembali, {{ auth()->user()->name }}! Pantau ringkasan aktivitas hari ini.</p>
    </header>

    <!-- Verse of the Day Section -->
    @if($verse)
    <div class="card glass" style="margin-bottom: 30px; background: linear-gradient(135deg, rgba(0, 81, 71, 0.05) 0%, rgba(255, 255, 255, 0.8) 100%); border-left: 5px solid var(--primary);">
        <div style="display: flex; gap: 20px; align-items: center;">
            <div style="font-size: 2rem; color: var(--primary); opacity: 0.5;"><i data-lucide="quote"></i></div>
            <div>
                <p style="font-size: 1.1rem; font-style: italic; font-weight: 600; color: var(--text-main); line-height: 1.6; margin-bottom: 8px;">
                    "{{ $verse->content }}"
                </p>
                <small style="font-weight: 800; color: var(--primary); text-transform: uppercase; letter-spacing: 1px;">— {{ $verse->reference }}</small>
            </div>
        </div>
    </div>
    @endif

    <!-- Statistics Grid -->
    <div class="stats-grid">
        <div class="stat-card glass card-hadir">
            <div class="stat-info">
                <div class="stat-label">Hadir Hari Ini</div>
                <div class="stat-value">{{ $stats['present'] }}</div>
            </div>
            <div class="stat-icon"><i data-lucide="user-check"></i></div>
        </div>
        <div class="stat-card glass card-terlambat">
            <div class="stat-info">
                <div class="stat-label">Terlambat</div>
                <div class="stat-value">{{ $stats['late'] }}</div>
            </div>
            <div class="stat-icon"><i data-lucide="clock"></i></div>
        </div>
        <div class="stat-card glass card-izin">
            <div class="stat-info">
                <div class="stat-label">Izin / Sakit</div>
                <div class="stat-value">{{ $stats['leave'] }}</div>
            </div>
            <div class="stat-icon"><i data-lucide="file-text"></i></div>
        </div>
        <div class="stat-card glass card-total">
            <div class="stat-info">
                <div class="stat-label">Total Anggota</div>
                <div class="stat-value">{{ auth()->user()->tenant->users()->count() }}</div>
            </div>
            <div class="stat-icon"><i data-lucide="users"></i></div>
        </div>
    </div>

    @if(auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin')
    <div style="display: grid; grid-template-columns: 2fr 1fr; gap: 24px; margin-top: 20px;">
        <!-- Recent Attendance -->
        <div class="card glass">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                <h2 style="font-size: 1.2rem; font-weight: 800;">Absensi Terbaru</h2>
                <a href="{{ route('attendances.index') }}" style="font-size: 0.8rem; font-weight: 700; color: var(--primary); text-decoration: none;">Lihat Semua</a>
            </div>
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Waktu</th>
                            <th>Nama</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($adminData['recent_attendances'] as $att)
                        <tr>
                            <td>{{ $att->created_at->format('H:i') }}</td>
                            <td><strong>{{ $att->user->name }}</strong></td>
                            <td>
                                <span class="badge-tipe {{ $att->is_late ? 'badge-danger' : 'badge-success' }}">
                                    {{ $att->is_late ? 'Terlambat' : 'Tepat Waktu' }}
                                </span>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="3" class="text-center">Belum ada absensi masuk hari ini.</td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Action Needed -->
        <div style="display: flex; flex-direction: column; gap: 20px;">
            <div class="card glass" style="background: white;">
                <h3 style="font-size: 0.9rem; font-weight: 800; color: var(--text-muted); text-transform: uppercase; margin-bottom: 15px;">Perlu Persetujuan</h3>
                <div style="display: flex; align-items: center; justify-content: space-between;">
                    <div style="font-size: 2rem; font-weight: 900; color: #f59e0b;">{{ $adminData['pending_leaves'] }}</div>
                    <a href="{{ route('leaves.index') }}" class="btn" style="padding: 10px 16px; font-size: 0.8rem; background: rgba(245, 158, 11, 0.1); color: #f59e0b;">Periksa</a>
                </div>
            </div>

            <div class="card glass" style="background: white;">
                <h3 style="font-size: 0.9rem; font-weight: 800; color: var(--text-muted); text-transform: uppercase; margin-bottom: 15px;">Masukan Baru (3 Hari Terakhir)</h3>
                <div style="display: flex; align-items: center; justify-content: space-between;">
                    <div style="font-size: 2rem; font-weight: 900; color: var(--primary);">{{ $adminData['new_feedback'] }}</div>
                    <a href="{{ route('feedback.index') }}" class="btn" style="padding: 10px 16px; font-size: 0.8rem; background: rgba(0, 81, 71, 0.1); color: var(--primary);">Baca</a>
                </div>
            </div>
        </div>
    </div>
    @else
        <!-- User View: My History Summary or Quick Actions -->
        <div class="card glass" style="margin-top: 20px;">
            <h2 style="font-size: 1.2rem; font-weight: 800; margin-bottom: 20px;">Aksi Cepat</h2>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px;">
                <a href="{{ route('attendances.create') }}" class="btn btn-primary" style="padding: 20px; flex-direction: column; gap: 8px;">
                    <i data-lucide="scan-face" style="width: 32px; height: 32px;"></i>
                    <span>Absen Sekarang</span>
                </a>
                <a href="{{ route('leaves.personal') }}" class="btn" style="padding: 20px; flex-direction: column; gap: 8px; background: white; border: 1.5px solid #e2e8f0; color: var(--text-main);">
                    <i data-lucide="calendar-plus" style="width: 32px; height: 32px; color: var(--primary);"></i>
                    <span>Ajukan Izin</span>
                </a>
                <a href="{{ route('attendances.history') }}" class="btn" style="padding: 20px; flex-direction: column; gap: 8px; background: white; border: 1.5px solid #e2e8f0; color: var(--text-main);">
                    <i data-lucide="history" style="width: 32px; height: 32px; color: #3b82f6;"></i>
                    <span>Riwayat Saya</span>
                </a>
            </div>
        </div>
    @endif
</div>
@endsection
