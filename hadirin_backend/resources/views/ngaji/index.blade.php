@extends('layouts.app')

@section('title', 'Laporan Halaqah Guru')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px; display: flex; justify-content: space-between; align-items: center;">
        <div>
            <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Laporan Halaqah Guru</h1>
            <p style="color: var(--text-muted); font-weight: 500">Log kehadiran kelompok ngaji guru.</p>
        </div>
        @if(auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin')
        <a href="{{ route('ngaji.create') }}" class="btn btn-primary">
            <i data-lucide="plus"></i> <span>Tambah Presensi</span>
        </a>
        @endif
    </header>

    <div class="card glass">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Waktu</th>
                        <th>Nama Anggota</th>
                        <th>Kelompok</th>
                        <th>Materi</th>
                        <th>Status</th>
                        @if(auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin')
                        <th>Aksi</th>
                        @endif
                    </tr>
                </thead>
                <tbody>
                    @forelse($logs as $log)
                    <tr>
                        <td data-label="Waktu">{{ $log->created_at->format('d M Y H:i') }}</td>
                        <td data-label="Nama" style="font-weight: 600;">{{ $log->user->name ?? '-' }}</td>
                        <td data-label="Kelompok">{{ $log->group->group_name ?? ($log->group->name ?? '-') }}</td>
                        <td data-label="Materi" style="color: var(--text-muted);">{{ \Illuminate\Support\Str::limit($log->materi, 40) ?? '-' }}</td>
                        <td data-label="Status">
                            @php $sc = $log->status == 'Hadir' ? '#10b981' : '#f59e0b'; @endphp
                            <span style="font-weight: 800; color: {{ $sc }}">{{ strtoupper($log->status ?? 'Hadir') }}</span>
                        </td>
                        @if(auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin')
                        <td data-label="Aksi">
                            <div style="display: flex; gap: 8px;">
                                <a href="{{ route('ngaji.edit', $log->id) }}" class="btn" style="padding: 8px; background: rgba(0,0,0,0.05); color: var(--text-main);" title="Edit">
                                    <i data-lucide="edit" style="width: 16px;"></i>
                                </a>
                                <form action="{{ route('ngaji.destroy', $log->id) }}" method="POST" onsubmit="return confirm('Hapus data halaqah ini?')" style="display:inline;">
                                    @csrf @method('DELETE')
                                    <button type="submit" class="btn" style="padding: 8px; background: rgba(239,68,68,0.1); color: #ef4444; border:none; cursor:pointer;" title="Hapus">
                                        <i data-lucide="trash" style="width: 16px;"></i>
                                    </button>
                                </form>
                            </div>
                        </td>
                        @endif
                    </tr>
                    @empty
                    <tr><td colspan="{{ (auth()->user()->role == 'admin' || auth()->user()->role == 'superadmin') ? '6' : '5' }}" style="text-align: center; color: var(--text-muted); padding: 30px;">Belum ada laporan presensi ngaji.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
