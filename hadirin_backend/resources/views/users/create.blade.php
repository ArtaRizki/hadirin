@extends('layouts.app')

@section('title', 'Tambah Anggota')

@section('content')
<div class="content-view">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Tambah Anggota Baru</h1>
        <p style="color: var(--text-muted); font-weight: 500">Daftarkan guru atau karyawan baru ke sistem.</p>
    </header>

    <div class="card glass" style="max-width: 600px;">
        <form action="{{ route('users.store') }}" method="POST">
            @csrf
            <div class="input-group">
                <label>ID Anggota / NIK</label>
                <input type="text" name="employee_id" required placeholder="Contoh: GURU-002" value="{{ old('employee_id') }}" />
                @error('employee_id') <span style="color: #ef4444; font-size: 0.8rem; font-weight: 600;">{{ $message }}</span> @enderror
            </div>

            <div class="input-group">
                <label>Nama Lengkap</label>
                <input type="text" name="name" required placeholder="Nama lengkap" value="{{ old('name') }}" />
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                <div class="input-group">
                    <label>Role</label>
                    <select name="role" required>
                        <option value="anggota">Anggota</option>
                        <option value="admin">Admin</option>
                    </select>
                </div>
                <div class="input-group">
                    <label>Jabatan / Divisi</label>
                    <select name="division">
                        <option value="">-- Pilih Jabatan --</option>
                        @foreach($positions as $pos)
                            <option value="{{ $pos->name }}">{{ $pos->name }}</option>
                        @endforeach
                        <option value="Lainnya">Lainnya</option>
                    </select>
                </div>
            </div>

            <div class="input-group">
                <label>Password Awal</label>
                <input type="password" name="password" required placeholder="Minimal 6 karakter" />
            </div>

            <div style="display: flex; gap: 15px; margin-top: 30px;">
                <button type="submit" class="btn btn-primary" style="flex: 1; padding: 15px;">
                    <i data-lucide="user-plus"></i> Simpan Anggota
                </button>
                <a href="{{ route('users.index') }}" class="btn" style="padding: 15px; background: #f1f5f9; color: var(--text-main); text-decoration: none; text-align: center;">Batal</a>
            </div>
        </form>
    </div>
</div>
@endsection
