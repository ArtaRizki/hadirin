@extends('layouts.app')

@section('title', 'Laporan Setoran Hafalan')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Laporan Setoran Hafalan</h1>
        <p style="color: var(--text-muted); font-weight: 500">Log monitoring hafalan Quran siswa.</p>
    </header>

    <div class="card glass">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Tanggal</th>
                        <th>Siswa</th>
                        <th>Guru / Musyrif</th>
                        <th>Surah & Ayat</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($logs as $log)
                    <tr>
                        <td>{{ $log->created_at->format('d M Y') }}</td>
                        <td>{{ $log->student->name ?? '-' }}</td>
                        <td>{{ $log->teacher->name ?? '-' }}</td>
                        <td>{{ $log->surah_name }} ({{ $log->start_verse }} - {{ $log->end_verse }})</td>
                        <td><span class="badge-tipe">{{ $log->status }}</span></td>
                    </tr>
                    @empty
                    <tr><td colspan="5" style="text-align: center; color: var(--text-muted); padding: 30px;">Belum ada laporan setoran.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
