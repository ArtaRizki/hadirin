@extends('layouts.app')

@section('title', 'Data Anggota')

@section('content')
<div class="content-view fade-in">
    <header style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 40px;">
        <div>
            <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Data Anggota</h1>
            <p style="color: var(--text-muted); font-weight: 500">Kelola daftar anggota instansi Anda.</p>
        </div>
    </header>

    <div class="card glass">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
            <h3 style="font-weight: 800; font-size: 1.2rem">Data Anggota Aktif</h3>
            <a href="{{ route('users.create') }}" class="btn btn-primary" style="padding: 10px 20px; font-size: 0.9rem; text-decoration: none;">
                <i data-lucide="plus" style="width: 16px; height: 16px;"></i> Tambah Anggota
            </a>
        </div>
        
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Nama</th>
                        <th>Role / Divisi</th>
                        <th>Status Perangkat</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($users as $user)
                    <tr>
                        <td style="font-weight: 600;">{{ $user->employee_id }}</td>
                        <td>{{ $user->name }}</td>
                        <td><span class="badge-tipe">{{ strtoupper($user->role) }}</span></td>
                        <td>
                            @if($user->device_id)
                                <span style="color: #10b981; font-weight: 600;"><i data-lucide="smartphone" style="width:14px; display:inline-block; vertical-align:middle;"></i> Terkunci</span>
                            @else
                                <span style="color: #f59e0b; font-weight: 600;">Bebas</span>
                            @endif
                        </td>
                        <td>
                            <div style="display: flex; gap: 8px;">
                                <a href="{{ route('users.edit', $user->id) }}" class="btn" style="padding: 6px 12px; font-size: 0.8rem; background: rgba(59, 130, 246, 0.1); color: #3b82f6; text-decoration: none;">Edit</a>
                                
                                <form action="{{ route('users.resetDevice', $user->id) }}" method="POST" style="display:inline;" onsubmit="return confirm('Reset perangkat dan wajah pengguna ini?');">
                                    @csrf
                                    <button type="submit" class="btn" style="padding: 6px 12px; font-size: 0.8rem; background: rgba(245, 158, 11, 0.1); color: #f59e0b; border: none; cursor: pointer;">Reset Device</button>
                                </form>

                                <form action="{{ route('users.destroy', $user->id) }}" method="POST" style="display:inline;" onsubmit="return confirm('Yakin ingin menghapus pengguna ini secara permanen?');">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="btn" style="padding: 6px 12px; font-size: 0.8rem; background: rgba(239, 68, 68, 0.1); color: #ef4444; border: none; cursor: pointer;">Hapus</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
