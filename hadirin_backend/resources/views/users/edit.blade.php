@extends('layouts.app')

@section('title', 'Edit Anggota')

@section('content')
<div class="content-view">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Edit Data Anggota</h1>
        <p style="color: var(--text-muted); font-weight: 500">Perbarui informasi guru atau karyawan.</p>
    </header>

    <div class="card glass" style="max-width: 600px;">
        <form action="{{ route('users.update', $user->id) }}" method="POST">
            @csrf
            @method('PUT')
            
            <div class="input-group">
                <label>ID Anggota / NIK (Read Only)</label>
                <input type="text" value="{{ $user->employee_id }}" disabled style="background: #f8fafc; cursor: not-allowed;" />
            </div>

            <div class="input-group">
                <label>Nama Lengkap</label>
                <input type="text" name="name" required value="{{ $user->name }}" />
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                <div class="input-group">
                    <label>Role</label>
                    <select name="role" required>
                        <option value="anggota" {{ $user->role == 'anggota' ? 'selected' : '' }}>Anggota</option>
                        <option value="admin" {{ $user->role == 'admin' ? 'selected' : '' }}>Admin</option>
                    </select>
                </div>
                <div class="input-group">
                    <label>Jabatan / Divisi</label>
                    <select name="division">
                        <option value="">-- Pilih Jabatan --</option>
                        @foreach($positions as $pos)
                            <option value="{{ $pos->name }}" {{ $user->division == $pos->name ? 'selected' : '' }}>{{ $pos->name }}</option>
                        @endforeach
                        <option value="Lainnya" {{ !in_array($user->division, $positions->pluck('name')->toArray()) && $user->division ? 'selected' : '' }}>Lainnya</option>
                    </select>
                </div>
            </div>

            <div class="input-group">
                <label>Password (Kosongkan jika tidak diganti)</label>
                <input type="password" name="password" placeholder="Masukkan password baru jika ingin ganti" />
            </div>

            <div style="display: flex; gap: 15px; margin-top: 30px;">
                <button type="submit" class="btn btn-primary" style="flex: 1; padding: 15px;">
                    <i data-lucide="save"></i> Simpan Perubahan
                </button>
                <a href="{{ route('users.index') }}" class="btn" style="padding: 15px; background: #f1f5f9; color: var(--text-main); text-decoration: none; text-align: center;">Batal</a>
            </div>
        </form>
    </div>
</div>
@endsection
