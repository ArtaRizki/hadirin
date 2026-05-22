@extends('layouts.app')

@section('title', 'Absensi Hari Ini')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
            Absensi Hari Ini
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Pantau kehadiran real-time seluruh anggota.
        </p>
    </header>

    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 16px; margin-bottom: 24px;">
        <div class="card glass" style="padding: 20px; text-align: center; border-left: 4px solid #16a34a;">
            <div style="font-size: 0.75rem; text-transform: uppercase; color: var(--text-muted); font-weight: 800; margin-bottom: 5px;">Hadir</div>
            <div style="font-size: 2rem; font-weight: 900; color: #16a34a">{{ $stats['present'] ?? 0 }}</div>
        </div>
        <div class="card glass" style="padding: 20px; text-align: center; border-left: 4px solid #d97706;">
            <div style="font-size: 0.75rem; text-transform: uppercase; color: var(--text-muted); font-weight: 800; margin-bottom: 5px;">Terlambat</div>
            <div style="font-size: 2rem; font-weight: 900; color: #d97706">{{ $stats['late'] ?? 0 }}</div>
        </div>
        <div class="card glass" style="padding: 20px; text-align: center; border-left: 4px solid #dc2626;">
            <div style="font-size: 0.75rem; text-transform: uppercase; color: var(--text-muted); font-weight: 800; margin-bottom: 5px;">Total Karyawan</div>
            <div style="font-size: 2rem; font-weight: 900; color: #dc2626">{{ auth()->user()->tenant->users()->count() }}</div>
        </div>
        <div class="card glass" style="padding: 20px; text-align: center; border-left: 4px solid #2563eb;">
            <div style="font-size: 0.75rem; text-transform: uppercase; color: var(--text-muted); font-weight: 800; margin-bottom: 5px;">Izin/Sakit</div>
            <div style="font-size: 2rem; font-weight: 900; color: #2563eb">{{ $stats['leave'] ?? 0 }}</div>
        </div>
    </div>

    <div class="card glass">
        <form action="{{ route('attendances.index') }}" method="GET" style="margin-bottom: 20px; display: flex; gap: 10px; flex-wrap: wrap;">
            <input type="date" name="date" value="{{ request('date', date('Y-m-d')) }}"
                style="flex: 1; min-width: 0; padding: 12px 16px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
            <button type="submit" class="btn btn-primary" style="flex-shrink: 0; padding: 12px 20px;">
                <i data-lucide="search"></i>
            </button>
        </form>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Waktu</th>
                        <th>Nama</th>
                        <th>Tipe</th>
                        <th>Status</th>
                        <th>Foto</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($attendances as $absen)
                    <tr>
                        <td data-label="Waktu">{{ $absen->created_at->format('H:i') }}</td>
                        <td data-label="Nama" style="font-weight: 600;">{{ $absen->user->name ?? '-' }}</td>
                        <td data-label="Tipe">
                            <span class="badge-tipe" style="background: {{ $absen->type == 'Masuk' ? 'rgba(16, 185, 129, 0.1)' : 'rgba(59, 130, 246, 0.1)' }}; color: {{ $absen->type == 'Masuk' ? '#10b981' : '#3b82f6' }};">
                                {{ $absen->type }}
                            </span>
                        </td>
                        <td data-label="Status">
                            <span class="badge-tipe" style="background: {{ $absen->status == 'Tepat Waktu' ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)' }}; color: {{ $absen->status == 'Tepat Waktu' ? '#10b981' : '#ef4444' }};">
                                {{ $absen->status }}
                            </span>
                        </td>
                        <td data-label="Foto">
                            @if($absen->photo_url && $absen->photo_url != 'No Photo')
                                <a href="{{ $absen->photo_url }}" target="_blank" style="color: var(--primary); text-decoration: none; font-weight: 600;">Lihat Foto</a>
                            @else
                                <span style="color: var(--text-muted); font-size: 0.8rem;">Tidak ada</span>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr><td colspan="5" style="text-align: center; color: var(--text-muted); padding: 40px;">Belum ada absensi pada tanggal ini.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        <div style="margin-top: 20px;">
            {{ $attendances->links('pagination::bootstrap-5') }}
        </div>
    </div>
</div>
@endsection
