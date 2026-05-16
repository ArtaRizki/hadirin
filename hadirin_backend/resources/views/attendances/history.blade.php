@extends('layouts.app')

@section('title', 'Riwayat Absensi')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
            Riwayat Absensi
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Daftar kehadiran Anda selama ini.
        </p>
    </header>

    <div class="card glass">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Waktu</th>
                        <th>Tipe</th>
                        <th>Status</th>
                        <th>Foto</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($attendances as $absen)
                    <tr>
                        <td>
                            <strong>{{ $absen->created_at->format('d M Y') }}</strong><br>
                            <small style="color: var(--text-muted)">{{ $absen->created_at->format('H:i') }}</small>
                        </td>
                        <td><span class="badge-tipe">{{ $absen->type }}</span></td>
                        <td>
                            <span style="font-weight: 800; color: {{ $absen->status == 'Tepat Waktu' ? '#10b981' : '#f59e0b' }}">
                                {{ strtoupper($absen->status) }}
                            </span>
                        </td>
                        <td>
                            @if($absen->photo_url && $absen->photo_url != 'No Photo')
                                <a href="{{ $absen->photo_url }}" target="_blank" style="color: var(--primary); font-weight: 600; text-decoration: none;">Lihat Foto</a>
                            @else
                                <span style="color: var(--text-muted); font-size: 0.8rem;">-</span>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr><td colspan="4" style="text-align: center; color: var(--text-muted); padding: 40px;">Belum ada riwayat absensi.</td></tr>
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
