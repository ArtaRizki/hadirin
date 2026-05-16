@extends('layouts.app')

@section('title', 'Edit Anggota')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
            Edit Anggota
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Perbarui data anggota.
        </p>
    </header>

    <div class="card glass" style="max-width: 600px;">
        <form action="{{ route('users.update', $user->id) }}" method="POST">
            @csrf
            @method('PUT')
            
            <div class="input-group">
                <label>ID Anggota</label>
                <input type="text" name="employee_id" required value="{{ old('employee_id', $user->employee_id) }}" />
                @error('employee_id') <span style="color: red; font-size: 0.8rem;">{{ $message }}</span> @enderror
            </div>

            <div class="input-group">
                <label>Nama Lengkap</label>
                <input type="text" name="name" required value="{{ old('name', $user->name) }}" />
            </div>

            <div class="input-group">
                <label>Role / Divisi</label>
                <select name="role" required style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    <option value="anggota" {{ $user->role == 'anggota' ? 'selected' : '' }}>Anggota (Guru/Karyawan)</option>
                    <option value="admin" {{ $user->role == 'admin' ? 'selected' : '' }}>Admin</option>
                </select>
            </div>

            <div class="input-group">
                <label>Password Baru (Opsional)</label>
                <input type="password" name="password" placeholder="Kosongkan jika tidak ingin diubah" />
            </div>

            <div style="display: flex; gap: 15px; margin-top: 30px;">
                <button type="submit" class="btn btn-primary" style="flex: 1; padding: 15px;">Update Data</button>
                <a href="{{ route('users.index') }}" class="btn" style="padding: 15px; background: rgba(0,0,0,0.05); color: var(--text-main); text-decoration: none; text-align: center;">Batal</a>
            </div>
        </form>
    </div>
</div>
@endsection
