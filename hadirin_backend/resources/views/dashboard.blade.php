@extends('layouts.app')

@section('title', 'Dashboard')

@section('content')
<div class="content-view fade-in">
    @if(in_array(strtolower(auth()->user()->role), ['admin', 'super admin', 'superadmin']))
        <!-- ADMIN DASHBOARD -->
        <header style="margin-bottom: 40px">
            <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
                Dashboard Kehadiran
            </h1>
            <p style="color: var(--text-muted); font-weight: 500">
                Pantau ringkasan aktivitas absensi hari ini.
            </p>
        </header>

        <div class="stats-grid">
            <div class="stat-card glass" style="border-left: 4px solid #10b981;">
                <div class="stat-label">Hadir Hari Ini</div>
                <div class="stat-value">{{ $stats['present'] ?? 0 }}</div>
            </div>
            <div class="stat-card glass" style="border-left: 4px solid #f59e0b;">
                <div class="stat-label">Terlambat</div>
                <div class="stat-value">{{ $stats['late'] ?? 0 }}</div>
            </div>
            <div class="stat-card glass" style="border-left: 4px solid #3b82f6;">
                <div class="stat-label">Izin / Sakit</div>
                <div class="stat-value">{{ $stats['leave'] ?? 0 }}</div>
            </div>
            <div class="stat-card glass" style="border-left: 4px solid #7c3aed;">
                <div class="stat-label">Total Anggota</div>
                <div class="stat-value">{{ auth()->user()->tenant->users()->count() }}</div>
            </div>
        </div>

        <div class="card glass" style="margin-top: 30px">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
                <h3 style="font-weight: 800; font-size: 1.2rem">Absensi Terbaru Hari Ini</h3>
                <span class="badge-tipe" style="background: rgba(124, 58, 237, 0.1); color: #7c3aed;">Live Data</span>
            </div>
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Waktu</th>
                            <th>Nama</th>
                            <th>Tipe</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($attendances as $absen)
                        <tr>
                            <td>{{ $absen->created_at->format('H:i') }}</td>
                            <td style="font-weight: 600;">{{ $absen->user->name ?? '-' }}</td>
                            <td><span class="badge-tipe">{{ $absen->type }}</span></td>
                            <td>
                                <span style="font-weight: 800; color: {{ $absen->status == 'Tepat Waktu' ? '#10b981' : '#f59e0b' }}">
                                    {{ strtoupper($absen->status) }}
                                </span>
                            </td>
                        </tr>
                        @empty
                        <tr><td colspan="4" style="text-align: center; color: var(--text-muted); padding: 40px;">Belum ada absensi hari ini</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    @else
        <!-- MEMBER DASHBOARD -->
        <header style="margin-bottom: 40px">
            <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
                Halo, {{ explode(' ', auth()->user()->name)[0] }}!
            </h1>
            <p style="color: var(--text-muted); font-weight: 500">
                Sudahkah Anda melakukan absensi hari ini?
            </p>
        </header>

        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 24px; margin-bottom: 40px;">
            <!-- Masuk Card -->
            <div class="card glass" style="padding: 30px; text-align: center; display: flex; flex-direction: column; align-items: center;">
                <div style="width: 64px; height: 64px; border-radius: 20px; background: rgba(16, 185, 129, 0.1); color: #10b981; display: flex; align-items: center; justify-content: center; margin-bottom: 20px;">
                    <i data-lucide="log-in" style="width: 32px; height: 32px;"></i>
                </div>
                <h3 style="font-weight: 800; margin-bottom: 8px;">Absen Masuk</h3>
                <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 24px;">Lakukan absensi saat memulai pekerjaan.</p>
                <button class="btn btn-primary" style="width: 100%; padding: 15px;" onclick="window.location.href='{{ route('attendances.create', ['type' => 'Masuk']) }}'">
                    Masuk Sekarang
                </button>
            </div>

            <!-- Pulang Card -->
            <div class="card glass" style="padding: 30px; text-align: center; display: flex; flex-direction: column; align-items: center;">
                <div style="width: 64px; height: 64px; border-radius: 20px; background: rgba(59, 130, 246, 0.1); color: #3b82f6; display: flex; align-items: center; justify-content: center; margin-bottom: 20px;">
                    <i data-lucide="log-out" style="width: 32px; height: 32px;"></i>
                </div>
                <h3 style="font-weight: 800; margin-bottom: 8px;">Absen Pulang</h3>
                <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 24px;">Lakukan absensi sebelum mengakhiri pekerjaan.</p>
                <button class="btn" style="width: 100%; padding: 15px; background: rgba(59, 130, 246, 0.1); color: #3b82f6;" onclick="window.location.href='{{ route('attendances.create', ['type' => 'Pulang']) }}'">
                    Pulang Sekarang
                </button>
            </div>
        </div>

        <div class="card glass">
            <h3 style="font-weight: 800; margin-bottom: 20px;">Riwayat Hari Ini</h3>
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Waktu</th>
                            <th>Tipe</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($attendances->where('user_id', auth()->id()) as $absen)
                        <tr>
                            <td>{{ $absen->created_at->format('H:i') }}</td>
                            <td><span class="badge-tipe">{{ $absen->type }}</span></td>
                            <td>
                                <span style="font-weight: 800; color: {{ $absen->status == 'Tepat Waktu' ? '#10b981' : '#f59e0b' }}">
                                    {{ strtoupper($absen->status) }}
                                </span>
                            </td>
                        </tr>
                        @empty
                        <tr><td colspan="3" style="text-align: center; color: var(--text-muted); padding: 30px;">Belum ada riwayat hari ini.</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    @endif
</div>
@endsection
