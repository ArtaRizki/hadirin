@extends('layouts.app')

@section('title', 'Tambah Anggota')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
            Tambah Anggota Baru
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Daftarkan guru atau karyawan baru ke sistem.
        </p>
    </header>

    <div class="card glass" style="max-width: 600px;">
        <form action="{{ route('users.store') }}" method="POST">
            @csrf
            <div class="input-group">
                <label>ID Anggota</label>
                <input type="text" name="employee_id" required placeholder="Contoh: GURU-002" value="{{ old('employee_id') }}" />
                @error('employee_id') <span style="color: red; font-size: 0.8rem;">{{ $message }}</span> @enderror
            </div>

            <div class="input-group">
                <label>Nama Lengkap</label>
                <input type="text" name="name" required placeholder="Nama lengkap" value="{{ old('name') }}" />
            </div>

            <div class="input-group">
                <label>Role / Divisi</label>
                <select name="role" required style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    <option value="anggota">Anggota (Guru/Karyawan)</option>
                    <option value="admin">Admin</option>
                </select>
            </div>

            <div class="input-group">
                <label>Password</label>
                <input type="password" name="password" required placeholder="Minimal 6 karakter" />
            </div>

            <div style="display: flex; gap: 15px; margin-top: 30px;">
                <button type="submit" class="btn btn-primary" style="flex: 1; padding: 15px;">Simpan</button>
                <a href="{{ route('users.index') }}" class="btn" style="padding: 15px; background: rgba(0,0,0,0.05); color: var(--text-main); text-decoration: none; text-align: center;">Batal</a>
            </div>
        </form>
    </div>
</div>
@endsection
