@extends('layouts.app')

@section('title', 'Laporan Briefing Harian')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px; display: flex; justify-content: space-between; align-items: center;">
        <div>
            <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Laporan Rapat & Briefing</h1>
            <p style="color: var(--text-muted); font-weight: 500">Log kehadiran untuk rapat dan briefing.</p>
        </div>
        @if(auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin')
        <a href="{{ route('briefings.create') }}" class="btn btn-primary">
            <i data-lucide="plus"></i> Tambah Briefing
        </a>
        @endif
    </header>

    <div class="card glass">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Tanggal</th>
                        <th>Waktu</th>
                        <th>Judul / Agenda</th>
                        <th>Pemateri / PIC</th>
                        <th>Jumlah Hadir</th>
                        @if(auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin')
                        <th>Aksi</th>
                        @endif
                    </tr>
                </thead>
                <tbody>
                    @forelse($briefings as $briefing)
                    <tr>
                        <td>{{ \Carbon\Carbon::parse($briefing->scheduled_date)->format('d M Y') }}</td>
                        <td>{{ $briefing->scheduled_time ?? '-' }}</td>
                        <td style="font-weight: 600;">{{ $briefing->title }}</td>
                        <td>{{ $briefing->speaker_name ?? '-' }}</td>
                        <td>{{ $briefing->attendances_count }} Peserta</td>
                        @if(auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin')
                        <td>
                            <div style="display: flex; gap: 8px;">
                                <a href="{{ route('briefings.edit', $briefing->id) }}" class="btn" style="padding: 8px; background: rgba(0,0,0,0.05); color: var(--text-main);" title="Edit"><i data-lucide="edit" style="width: 16px;"></i></a>
                                <form action="{{ route('briefings.destroy', $briefing->id) }}" method="POST" onsubmit="return confirm('Hapus briefing ini beserta seluruh data presensinya?')" style="display:inline;">
                                    @csrf @method('DELETE')
                                    <button type="submit" class="btn" style="padding: 8px; background: rgba(239,68,68,0.1); color: #ef4444; border:none; cursor:pointer;" title="Hapus"><i data-lucide="trash" style="width: 16px;"></i></button>
                                </form>
                            </div>
                        </td>
                        @endif
                    </tr>
                    @empty
                    <tr><td colspan="{{ (auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin') ? '6' : '5' }}" style="text-align: center; color: var(--text-muted); padding: 30px;">Belum ada laporan rapat/briefing.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
