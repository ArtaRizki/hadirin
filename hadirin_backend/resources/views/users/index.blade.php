@extends('layouts.app')

@section('title', 'Data Anggota')

@section('content')
<div class="content-view">
    <header style="margin-bottom: 30px; display: flex; justify-content: space-between; align-items: flex-start;">
        <div>
            <h1 style="font-size: 2.2rem; font-weight: 900; color: var(--text-main); letter-spacing: -1px;">Data Anggota</h1>
            <p style="color: var(--text-muted); font-weight: 500;">Kelola daftar guru dan karyawan sekolah.</p>
        </div>
        <a href="{{ route('users.create') }}" class="btn btn-primary">
            <i data-lucide="user-plus"></i> Tambah Anggota
        </a>
    </header>

    <div class="card glass">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Anggota</th>
                        <th>Jabatan</th>
                        <th>Role</th>
                        <th>Status Device</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($users as $u)
                    <tr>
                        <td data-label="Anggota">
                            <div style="display: flex; align-items: center; gap: 12px">
                                <div style="width: 40px; height: 40px; border-radius: 12px; background: #f1f5f9; display: flex; align-items: center; justify-content: center; color: var(--primary);">
                                    <i data-lucide="user"></i>
                                </div>
                                <div>
                                    <div style="font-weight: 800; color: var(--text-main);">{{ $u->name }}</div>
                                    <div style="font-size: 0.75rem; color: var(--text-muted); font-weight: 600;">ID: {{ $u->employee_id }}</div>
                                </div>
                            </div>
                        </td>
                        <td data-label="Jabatan">
                            <span class="badge-tipe" style="background: rgba(0, 81, 71, 0.05); color: var(--primary);">
                                {{ $u->division ?? 'Staf' }}
                            </span>
                        </td>
                        <td data-label="Role">
                            <span class="badge-tipe {{ $u->role == 'admin' ? 'badge-warning' : 'badge-neutral' }}">
                                {{ strtoupper($u->role) }}
                            </span>
                        </td>
                        <td data-label="Status Device">
                            @if($u->device_id)
                                <div style="display: flex; align-items: center; gap: 6px; color: #10b981; font-weight: 700; font-size: 0.85rem;">
                                    <i data-lucide="smartphone" style="width: 14px;"></i> Terikat
                                </div>
                            @else
                                <div style="color: var(--text-muted); font-size: 0.85rem;">Belum Terikat</div>
                            @endif
                        </td>
                        <td data-label="Aksi">
                            <div style="display: flex; gap: 8px;">
                                <a href="{{ route('users.edit', $u->id) }}" class="btn" style="padding: 8px; background: #f1f5f9; color: #3b82f6;" title="Edit">
                                    <i data-lucide="edit-3"></i>
                                </a>
                                
                                @if($u->device_id)
                                <form action="{{ route('users.resetDevice', $u->id) }}" method="POST">
                                    @csrf
                                    <button type="submit" class="btn" style="padding: 8px; background: #fffbeb; color: #f59e0b;" title="Reset Device" onclick="return confirm('Reset perangkat {{ $u->name }}?')">
                                        <i data-lucide="refresh-cw"></i>
                                    </button>
                                </form>
                                @endif

                                @if($u->id != auth()->id())
                                <form action="{{ route('users.destroy', $u->id) }}" method="POST">
                                    @csrf @method('DELETE')
                                    <button type="submit" class="btn" style="padding: 8px; background: #fef2f2; color: #ef4444;" title="Hapus" onclick="return confirm('Hapus {{ $u->name }}?')">
                                        <i data-lucide="trash-2"></i>
                                    </button>
                                </form>
                                @endif
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="text-center">Belum ada data anggota.</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
