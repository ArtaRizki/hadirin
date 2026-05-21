@extends('layouts.app')

@section('title', 'Edit Data Halaqah')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Edit Data Halaqah</h1>
        <p style="color: var(--text-muted); font-weight: 500">Perbarui data presensi kelompok halaqah.</p>
    </header>

    <div class="card glass" style="max-width: 600px;">
        <form action="{{ route('ngaji.update', $log->id) }}" method="POST">
            @csrf @method('PUT')

            <div class="input-group">
                <label>Nama Guru</label>
                <select name="user_id" required style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    <option value="">-- Pilih Guru --</option>
                    @foreach($users as $user)
                        <option value="{{ $user->id }}" {{ $log->user_id == $user->id ? 'selected' : '' }}>{{ $user->name }}</option>
                    @endforeach
                </select>
            </div>

            <div class="input-group">
                <label>Kelompok Halaqah</label>
                <select name="ngaji_group_id" required style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    <option value="">-- Pilih Kelompok --</option>
                    @foreach($groups as $group)
                        <option value="{{ $group->id }}" {{ $log->ngaji_group_id == $group->id ? 'selected' : '' }}>{{ $group->group_name ?? $group->name }}</option>
                    @endforeach
                </select>
            </div>

            <div class="input-group">
                <label>Status Kehadiran</label>
                <select name="status" required style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    @foreach(['Hadir', 'Izin', 'Sakit', 'Alpha'] as $s)
                        <option value="{{ $s }}" {{ ($log->status ?? 'Hadir') == $s ? 'selected' : '' }}>{{ $s }}</option>
                    @endforeach
                </select>
            </div>

            <div class="input-group">
                <label>Lokasi / Keterangan</label>
                <input type="text" name="location" value="{{ old('location', $log->location) }}" placeholder="Cth: Masjid Sekolah" />
            </div>

            <div class="input-group">
                <label>Materi / Pencapaian (Opsional)</label>
                <textarea name="materi" rows="3" placeholder="Apa yang dibahas hari ini?">{{ old('materi', $log->materi) }}</textarea>
            </div>

            <div style="display: flex; gap: 15px; margin-top: 30px;">
                <a href="{{ route('ngaji.index') }}" class="btn" style="flex: 1; padding: 15px; text-align: center;">Batal</a>
                <button type="submit" class="btn btn-primary" style="flex: 2; padding: 15px;">Simpan Perubahan</button>
            </div>
        </form>
    </div>
</div>
@endsection
