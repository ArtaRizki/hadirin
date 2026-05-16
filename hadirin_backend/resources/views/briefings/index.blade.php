@extends('layouts.app')

@section('title', 'Laporan Rapat / Briefing')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Laporan Rapat & Briefing</h1>
        <p style="color: var(--text-muted); font-weight: 500">Log kehadiran untuk rapat dan briefing.</p>
    </header>

    <div class="card glass">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Tanggal</th>
                        <th>Judul / Agenda</th>
                        <th>Pemateri / PIC</th>
                        <th>Jumlah Hadir</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($briefings as $briefing)
                    <tr>
                        <td>{{ $briefing->created_at->format('d M Y') }}</td>
                        <td style="font-weight: 600;">{{ $briefing->title }}</td>
                        <td>{{ $briefing->speaker_name }}</td>
                        <td>{{ $briefing->attendances_count }} Peserta</td>
                        <td>
                            <button class="btn" style="padding: 6px 12px; font-size: 0.8rem; background: rgba(59, 130, 246, 0.1); color: #3b82f6;" onclick="alert('Fitur detail peserta dalam tahap pengembangan.')">Lihat Detail</button>
                        </td>
                    </tr>
                    @empty
                    <tr><td colspan="5" style="text-align: center; color: var(--text-muted); padding: 30px;">Belum ada laporan rapat/briefing.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
