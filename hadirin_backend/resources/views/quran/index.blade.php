@extends('layouts.app')

@section('title', 'Laporan Tadarus Guru')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px; display: flex; justify-content: space-between; align-items: center;">
        <div>
            <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Laporan Tadarus Guru</h1>
            <p style="color: var(--text-muted); font-weight: 500">Log setoran hafalan Quran guru.</p>
        </div>
        @if(auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin')
        <a href="{{ route('quran.create') }}" class="btn btn-primary">
            <i data-lucide="plus"></i> Tambah Setoran
        </a>
        @endif
    </header>

    <div class="card glass">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Tanggal</th>
                        <th>Guru</th>
                        <th>Materi / Surah</th>
                        <th>Halaman / Ayat</th>
                        <th>Nilai</th>
                        <th>Keterangan</th>
                        @if(auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin')
                        <th>Aksi</th>
                        @endif
                    </tr>
                </thead>
                <tbody>
                    @forelse($logs as $log)
                    <tr>
                        <td>{{ $log->created_at->format('d M Y') }}</td>
                        <td style="font-weight: 600;">{{ $log->user->name ?? '-' }}</td>
                        <td>{{ $log->quranMaster->name ?? '-' }}</td>
                        <td>{{ $log->halaman_ayat ?? '-' }}</td>
                        <td><span class="badge-tipe">{{ $log->nilai ?? '-' }}</span></td>
                        <td style="color: var(--text-muted);">{{ $log->keterangan ?? '-' }}</td>
                        @if(auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin')
                        <td>
                            <div style="display: flex; gap: 8px;">
                                <a href="{{ route('quran.edit', $log->id) }}" class="btn" style="padding: 8px; background: rgba(0,0,0,0.05); color: var(--text-main);" title="Edit"><i data-lucide="edit" style="width: 16px;"></i></a>
                                <form action="{{ route('quran.destroy', $log->id) }}" method="POST" onsubmit="return confirm('Hapus data setoran ini?')" style="display:inline;">
                                    @csrf @method('DELETE')
                                    <button type="submit" class="btn" style="padding: 8px; background: rgba(239,68,68,0.1); color: #ef4444; border:none; cursor:pointer;" title="Hapus"><i data-lucide="trash" style="width: 16px;"></i></button>
                                </form>
                            </div>
                        </td>
                        @endif
                    </tr>
                    @empty
                    <tr><td colspan="{{ (auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin') ? '7' : '6' }}" style="text-align: center; color: var(--text-muted); padding: 30px;">Belum ada laporan setoran.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
