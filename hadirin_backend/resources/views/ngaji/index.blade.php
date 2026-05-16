@extends('layouts.app')

@section('title', 'Laporan Presensi Ngaji')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Laporan Ngaji / Halaqah</h1>
        <p style="color: var(--text-muted); font-weight: 500">Log kehadiran kelompok ngaji guru.</p>
    </header>

    <div class="card glass">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Waktu</th>
                        <th>Nama Anggota</th>
                        <th>Kelompok (Mentor)</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($logs as $log)
                    <tr>
                        <td>{{ $log->created_at->format('d M Y H:i') }}</td>
                        <td>{{ $log->user->name ?? '-' }}</td>
                        <td>{{ $log->group->group_name ?? '-' }}</td>
                        <td>
                            <span style="font-weight: 800; color: {{ $log->status == 'Hadir' ? '#10b981' : '#f59e0b' }}">
                                {{ strtoupper($log->status) }}
                            </span>
                        </td>
                    </tr>
                    @empty
                    <tr><td colspan="4" style="text-align: center; color: var(--text-muted); padding: 30px;">Belum ada laporan presensi ngaji.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
