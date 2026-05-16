@extends('layouts.app')

@section('title', 'Jadwal Kegiatan')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 40px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
            Jadwal Kegiatan
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Manajemen jadwal rapat, upacara, dan kegiatan lainnya.
        </p>
    </header>

    <div class="card glass">
        <div style="display: flex; gap: 12px; margin-bottom: 24px">
            <button class="btn btn-primary" onclick="alert('Fitur tambah kegiatan sedang disesuaikan. Silakan gunakan aplikasi mobile untuk sementara.')">
                <i data-lucide="plus"></i> Tambah Kegiatan
            </button>
        </div>
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Waktu Kegiatan</th>
                        <th>Nama Kegiatan</th>
                        <th>Tipe</th>
                        <th>Deskripsi</th>
                        <th>Status</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($activities ?? [] as $activity)
                    <tr>
                        <td>{{ $activity->scheduled_at->format('d M Y H:i') }}</td>
                        <td style="font-weight: 600;">{{ $activity->name }}</td>
                        <td><span class="badge-tipe">{{ $activity->type }}</span></td>
                        <td style="color: var(--text-muted);">{{ Str::limit($activity->description, 50) }}</td>
                        <td>
                            @if($activity->scheduled_at->isPast())
                                <span class="badge-tipe" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">Selesai</span>
                            @else
                                <span class="badge-tipe" style="background: rgba(245, 158, 11, 0.1); color: #f59e0b;">Akan Datang</span>
                            @endif
                        </td>
                        <td>
                            <div style="display: flex; gap: 8px;">
                                <button class="btn" style="padding: 8px; background: rgba(0,0,0,0.05); color: var(--text-main);" title="Edit"><i data-lucide="edit" style="width: 16px;"></i></button>
                                <button class="btn" style="padding: 8px; background: rgba(59, 130, 246, 0.1); color: #3b82f6;" title="Lihat Absensi"><i data-lucide="users" style="width: 16px;"></i></button>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 40px;">Belum ada jadwal kegiatan.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
